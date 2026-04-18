package com.athvacr.pipecraft_ar.rendering

import android.opengl.GLES20
import android.opengl.Matrix
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer

class PointLineRenderer {

    // ─── Point program (기존 원형 포인트용) ─────────────────
    private var pointProgram = 0
    private var positionAttrib = 0
    private var mvpMatrixUniform = 0
    private var colorUniform = 0
    private var pointSizeUniform = 0

    // ─── Line program (쿼드 라인용 — GL_TRIANGLE_STRIP) ────
    private var lineProgram = 0
    private var linePositionAttrib = 0
    private var lineColorUniform = 0

    // 재사용 버퍼 — 매 프레임 할당 방지
    private val mvpMatrix = FloatArray(16)
    private var pointBuffer: FloatBuffer = allocateBuffer(3)    // xyz × 1
    private var quadLineBuffer: FloatBuffer = allocateBuffer(12) // xyz × 4 vertices

    fun createOnGlThread() {
        // ─── 포인트용 프로그램 ──────────────────────────────
        val pointVS = loadShader(GLES20.GL_VERTEX_SHADER, POINT_VERTEX_SHADER)
        val pointFS = loadShader(GLES20.GL_FRAGMENT_SHADER, POINT_FRAGMENT_SHADER)

        pointProgram = GLES20.glCreateProgram().also {
            GLES20.glAttachShader(it, pointVS)
            GLES20.glAttachShader(it, pointFS)
            GLES20.glLinkProgram(it)
            checkLinkStatus(it)
        }

        positionAttrib = GLES20.glGetAttribLocation(pointProgram, "a_Position")
        mvpMatrixUniform = GLES20.glGetUniformLocation(pointProgram, "u_MvpMatrix")
        colorUniform = GLES20.glGetUniformLocation(pointProgram, "u_Color")
        pointSizeUniform = GLES20.glGetUniformLocation(pointProgram, "u_PointSize")

        // ─── 라인용 프로그램 ───────────────────────────────
        val lineVS = loadShader(GLES20.GL_VERTEX_SHADER, LINE_VERTEX_SHADER)
        val lineFS = loadShader(GLES20.GL_FRAGMENT_SHADER, LINE_FRAGMENT_SHADER)

        lineProgram = GLES20.glCreateProgram().also {
            GLES20.glAttachShader(it, lineVS)
            GLES20.glAttachShader(it, lineFS)
            GLES20.glLinkProgram(it)
            checkLinkStatus(it)
        }

        linePositionAttrib = GLES20.glGetAttribLocation(lineProgram, "a_Position")
        lineColorUniform = GLES20.glGetUniformLocation(lineProgram, "u_Color")
    }

    fun drawPoint(
        point: FloatArray,
        viewMatrix: FloatArray,
        projMatrix: FloatArray,
        color: FloatArray = floatArrayOf(1f, 0.62f, 0.04f, 1f),
        pointSize: Float = 80f
    ) {
        Matrix.multiplyMM(mvpMatrix, 0, projMatrix, 0, viewMatrix, 0)

        pointBuffer.clear()
        pointBuffer.put(point, 0, 3)
        pointBuffer.position(0)

        GLES20.glUseProgram(pointProgram)
        GLES20.glEnable(GLES20.GL_BLEND)
        GLES20.glBlendFunc(GLES20.GL_SRC_ALPHA, GLES20.GL_ONE_MINUS_SRC_ALPHA)
        GLES20.glUniformMatrix4fv(mvpMatrixUniform, 1, false, mvpMatrix, 0)
        GLES20.glUniform4fv(colorUniform, 1, color, 0)
        GLES20.glUniform1f(pointSizeUniform, pointSize)

        GLES20.glEnableVertexAttribArray(positionAttrib)
        GLES20.glVertexAttribPointer(positionAttrib, 3, GLES20.GL_FLOAT, false, 0, pointBuffer)
        GLES20.glDrawArrays(GLES20.GL_POINTS, 0, 1)
        GLES20.glDisableVertexAttribArray(positionAttrib)
        GLES20.glDisable(GLES20.GL_BLEND)
    }

    fun drawLine(
        p1: FloatArray,
        p2: FloatArray,
        viewMatrix: FloatArray,
        projMatrix: FloatArray,
        color: FloatArray = floatArrayOf(0.22f, 0.74f, 0.97f, 1f),
        lineWidth: Float = 24f,
        screenWidth: Int = 1080,
        screenHeight: Int = 1920
    ) {
        // 1) MVP 행렬
        Matrix.multiplyMM(mvpMatrix, 0, projMatrix, 0, viewMatrix, 0)

        // 2) 월드 → 클립 좌표 변환
        val clip1 = FloatArray(4)
        val clip2 = FloatArray(4)
        Matrix.multiplyMV(clip1, 0, mvpMatrix, 0, floatArrayOf(p1[0], p1[1], p1[2], 1f), 0)
        Matrix.multiplyMV(clip2, 0, mvpMatrix, 0, floatArrayOf(p2[0], p2[1], p2[2], 1f), 0)

        // 카메라 뒤에 있으면 그리지 않음
        if (clip1[3] <= 0.0001f || clip2[3] <= 0.0001f) return

        // 3) NDC 변환
        val ndc1x = clip1[0] / clip1[3]
        val ndc1y = clip1[1] / clip1[3]
        val ndc2x = clip2[0] / clip2[3]
        val ndc2y = clip2[1] / clip2[3]

        // 4) 선의 수직 벡터 (화면 비율 보정)
        val aspect = screenWidth.toFloat() / screenHeight.toFloat()
        val dx = ndc2x - ndc1x
        val dy = ndc2y - ndc1y

        var perpX = -dy * aspect
        var perpY = dx / aspect
        val perpLen = Math.sqrt((perpX * perpX + perpY * perpY).toDouble()).toFloat()
        if (perpLen < 0.00001f) return
        perpX /= perpLen
        perpY /= perpLen

        // 5) NDC 단위 반폭 (lineWidth 픽셀 → NDC)
        val halfWidthNdc = lineWidth / screenWidth.toFloat()
        val ox = perpX * halfWidthNdc
        val oy = perpY * halfWidthNdc

        // 6) 4개 꼭짓점 (NDC 좌표, z는 클립에서 가져옴)
        val z1 = clip1[2] / clip1[3]
        val z2 = clip2[2] / clip2[3]

        quadLineBuffer.clear()
        quadLineBuffer.put(ndc1x - ox); quadLineBuffer.put(ndc1y - oy); quadLineBuffer.put(z1)
        quadLineBuffer.put(ndc1x + ox); quadLineBuffer.put(ndc1y + oy); quadLineBuffer.put(z1)
        quadLineBuffer.put(ndc2x - ox); quadLineBuffer.put(ndc2y - oy); quadLineBuffer.put(z2)
        quadLineBuffer.put(ndc2x + ox); quadLineBuffer.put(ndc2y + oy); quadLineBuffer.put(z2)
        quadLineBuffer.position(0)

        // 7) 렌더링
        GLES20.glUseProgram(lineProgram)
        GLES20.glEnable(GLES20.GL_BLEND)
        GLES20.glBlendFunc(GLES20.GL_SRC_ALPHA, GLES20.GL_ONE_MINUS_SRC_ALPHA)
        GLES20.glDepthMask(false)  // z-fighting 방지

        GLES20.glUniform4fv(lineColorUniform, 1, color, 0)

        GLES20.glEnableVertexAttribArray(linePositionAttrib)
        GLES20.glVertexAttribPointer(linePositionAttrib, 3, GLES20.GL_FLOAT, false, 0, quadLineBuffer)
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)
        GLES20.glDisableVertexAttribArray(linePositionAttrib)

        GLES20.glDepthMask(true)
        GLES20.glDisable(GLES20.GL_BLEND)
    }

    private fun allocateBuffer(floatCount: Int): FloatBuffer {
        require(floatCount in 1..1024) { "floatCount out of safe range: $floatCount" }
        return ByteBuffer.allocateDirect(floatCount * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()
    }

    private fun loadShader(type: Int, code: String): Int {
        return GLES20.glCreateShader(type).also {
            GLES20.glShaderSource(it, code)
            GLES20.glCompileShader(it)
            val status = IntArray(1)
            GLES20.glGetShaderiv(it, GLES20.GL_COMPILE_STATUS, status, 0)
            if (status[0] == 0) {
                val log = GLES20.glGetShaderInfoLog(it)
                GLES20.glDeleteShader(it)
                throw RuntimeException("Shader compile failed: $log")
            }
        }
    }

    private fun checkLinkStatus(program: Int) {
        val linkStatus = IntArray(1)
        GLES20.glGetProgramiv(program, GLES20.GL_LINK_STATUS, linkStatus, 0)
        if (linkStatus[0] == 0) {
            val log = GLES20.glGetProgramInfoLog(program)
            GLES20.glDeleteProgram(program)
            throw RuntimeException("Program link failed: $log")
        }
    }

    companion object {
        // ─── 포인트용 셰이더 (원형 smoothstep) ─────────────
        private const val POINT_VERTEX_SHADER = """
            uniform mat4 u_MvpMatrix;
            uniform float u_PointSize;
            attribute vec4 a_Position;
            void main() {
                gl_Position = u_MvpMatrix * a_Position;
                gl_PointSize = u_PointSize;
            }
        """

        private const val POINT_FRAGMENT_SHADER = """
            precision mediump float;
            uniform vec4 u_Color;
            void main() {
                vec2 coord = gl_PointCoord - vec2(0.5);
                float dist = length(coord);
                if (dist > 0.5) discard;
                float alpha = 1.0 - smoothstep(0.38, 0.5, dist);
                gl_FragColor = vec4(u_Color.rgb, u_Color.a * alpha);
            }
        """

        // ─── 라인용 셰이더 (쿼드 — NDC 직접 입력) ──────────
        private const val LINE_VERTEX_SHADER = """
            attribute vec4 a_Position;
            void main() {
                gl_Position = a_Position;
            }
        """

        private const val LINE_FRAGMENT_SHADER = """
            precision mediump float;
            uniform vec4 u_Color;
            void main() {
                gl_FragColor = u_Color;
            }
        """
    }
}
