package com.athvacr.pipecraft_ar.rendering

import android.opengl.GLES11Ext
import android.opengl.GLES20
import com.google.ar.core.Coordinates2d
import com.google.ar.core.Frame
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer

/**
 * ARCore 카메라 배경 렌더러.
 * Google ARCore SDK HelloAR 샘플 기반.
 */
class BackgroundRenderer {

    private var quadProgram = 0
    private var quadPositionAttrib = 0
    private var quadTexCoordAttrib = 0
    private var cameraTextureId = -1
    private var cameraTextureUniform = 0

    companion object {
        private const val COORDS_PER_VERTEX = 2
        private const val FLOAT_SIZE = 4
        private const val TEXCOORDS_PER_VERTEX = 2

        // NDC 풀스크린 쿼드
        private val QUAD_COORDS = floatArrayOf(
            -1.0f, -1.0f,
            +1.0f, -1.0f,
            -1.0f, +1.0f,
            +1.0f, +1.0f,
        )

        private const val VERTEX_SHADER =
            "attribute vec4 a_Position;\n" +
            "attribute vec2 a_TexCoord;\n" +
            "varying vec2 v_TexCoord;\n" +
            "void main() {\n" +
            "   gl_Position = a_Position;\n" +
            "   v_TexCoord = a_TexCoord;\n" +
            "}\n"

        private const val FRAGMENT_SHADER =
            "#extension GL_OES_EGL_image_external : require\n" +
            "precision mediump float;\n" +
            "varying vec2 v_TexCoord;\n" +
            "uniform samplerExternalOES sTexture;\n" +
            "void main() {\n" +
            "    gl_FragColor = texture2D(sTexture, v_TexCoord);\n" +
            "}\n"
    }

    private lateinit var quadCoordsBuffer: FloatBuffer

    // 입력 UV (NDC 좌표에 대응) — transformDisplayUvCoords의 입력
    private lateinit var quadTexCoordsInputBuffer: FloatBuffer
    // 출력 UV — transformDisplayUvCoords의 출력, 실제 드로우에 사용
    private lateinit var quadTexCoordsTransformedBuffer: FloatBuffer

    /**
     * GL 스레드에서 호출. 텍스처와 셰이더를 초기화한다.
     * 반환된 textureId를 Session.setCameraTextureName()에 전달해야 한다.
     */
    fun createOnGlThread(): Int {
        // 외부 텍스처 생성
        val textures = IntArray(1)
        GLES20.glGenTextures(1, textures, 0)
        cameraTextureId = textures[0]

        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, cameraTextureId)
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE)
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE)
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)

        // 버텍스 버퍼
        quadCoordsBuffer = ByteBuffer.allocateDirect(QUAD_COORDS.size * FLOAT_SIZE)
            .order(ByteOrder.nativeOrder()).asFloatBuffer().apply {
                put(QUAD_COORDS)
                position(0)
            }

        // UV 입력 버퍼 — OPENGL_NORMALIZED_DEVICE_COORDINATES에 대응하는 기본 UV
        val defaultUvs = floatArrayOf(
            0.0f, 1.0f,
            1.0f, 1.0f,
            0.0f, 0.0f,
            1.0f, 0.0f,
        )
        quadTexCoordsInputBuffer = ByteBuffer.allocateDirect(defaultUvs.size * FLOAT_SIZE)
            .order(ByteOrder.nativeOrder()).asFloatBuffer().apply {
                put(defaultUvs)
                position(0)
            }

        // UV 출력 버퍼 (transformDisplayUvCoords 결과 저장용)
        quadTexCoordsTransformedBuffer = ByteBuffer.allocateDirect(defaultUvs.size * FLOAT_SIZE)
            .order(ByteOrder.nativeOrder()).asFloatBuffer()

        // 셰이더 컴파일 & 링크
        val vertexShader = loadShader(GLES20.GL_VERTEX_SHADER, VERTEX_SHADER)
        val fragmentShader = loadShader(GLES20.GL_FRAGMENT_SHADER, FRAGMENT_SHADER)

        quadProgram = GLES20.glCreateProgram()
        GLES20.glAttachShader(quadProgram, vertexShader)
        GLES20.glAttachShader(quadProgram, fragmentShader)
        GLES20.glLinkProgram(quadProgram)

        val linkStatus = IntArray(1)
        GLES20.glGetProgramiv(quadProgram, GLES20.GL_LINK_STATUS, linkStatus, 0)
        if (linkStatus[0] != GLES20.GL_TRUE) {
            val log = GLES20.glGetProgramInfoLog(quadProgram)
            GLES20.glDeleteProgram(quadProgram)
            throw RuntimeException("Program link failed: $log")
        }

        quadPositionAttrib = GLES20.glGetAttribLocation(quadProgram, "a_Position")
        quadTexCoordAttrib = GLES20.glGetAttribLocation(quadProgram, "a_TexCoord")
        cameraTextureUniform = GLES20.glGetUniformLocation(quadProgram, "sTexture")

        return cameraTextureId
    }

    fun getTextureId(): Int = cameraTextureId

    /**
     * 카메라 배경을 그린다. 매 프레임 session.update() 후 호출.
     */
    fun draw(frame: Frame) {
        // 디스플레이 지오메트리가 변경되면 UV 좌표 재계산
        if (frame.hasDisplayGeometryChanged()) {
            frame.transformDisplayUvCoords(quadTexCoordsInputBuffer, quadTexCoordsTransformedBuffer)
        }

        // 깊이 테스트/쓰기 OFF — 배경은 항상 뒤
        GLES20.glDisable(GLES20.GL_DEPTH_TEST)
        GLES20.glDepthMask(false)

        GLES20.glUseProgram(quadProgram)

        // 텍스처 바인딩
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, cameraTextureId)
        GLES20.glUniform1i(cameraTextureUniform, 0)

        // 버텍스 좌표
        GLES20.glEnableVertexAttribArray(quadPositionAttrib)
        GLES20.glVertexAttribPointer(
            quadPositionAttrib, COORDS_PER_VERTEX, GLES20.GL_FLOAT,
            false, 0, quadCoordsBuffer
        )

        // 텍스처 좌표 (변환된 출력 버퍼 사용)
        GLES20.glEnableVertexAttribArray(quadTexCoordAttrib)
        GLES20.glVertexAttribPointer(
            quadTexCoordAttrib, TEXCOORDS_PER_VERTEX, GLES20.GL_FLOAT,
            false, 0, quadTexCoordsTransformedBuffer
        )

        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)

        // 정리
        GLES20.glDisableVertexAttribArray(quadPositionAttrib)
        GLES20.glDisableVertexAttribArray(quadTexCoordAttrib)

        GLES20.glDepthMask(true)
        GLES20.glEnable(GLES20.GL_DEPTH_TEST)
    }

    private fun loadShader(type: Int, code: String): Int {
        val shader = GLES20.glCreateShader(type)
        GLES20.glShaderSource(shader, code)
        GLES20.glCompileShader(shader)

        val compileStatus = IntArray(1)
        GLES20.glGetShaderiv(shader, GLES20.GL_COMPILE_STATUS, compileStatus, 0)
        if (compileStatus[0] != GLES20.GL_TRUE) {
            val log = GLES20.glGetShaderInfoLog(shader)
            GLES20.glDeleteShader(shader)
            throw RuntimeException("Shader compile failed: $log")
        }
        return shader
    }
}
