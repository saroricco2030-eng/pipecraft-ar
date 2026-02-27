package com.athvacr.pipecraft_ar.rendering

import android.opengl.GLES20
import android.opengl.Matrix
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer

class PointLineRenderer {

    private var program = 0
    private var positionAttrib = 0
    private var mvpMatrixUniform = 0
    private var colorUniform = 0
    private var pointSizeUniform = 0

    // 재사용 버퍼 — 매 프레임 할당 방지
    private val mvpMatrix = FloatArray(16)
    private var pointBuffer: FloatBuffer = allocateBuffer(3)   // xyz × 1
    private var lineBuffer: FloatBuffer = allocateBuffer(6)    // xyz × 2

    fun createOnGlThread() {
        val vertexShader = loadShader(GLES20.GL_VERTEX_SHADER, VERTEX_SHADER)
        val fragmentShader = loadShader(GLES20.GL_FRAGMENT_SHADER, FRAGMENT_SHADER)

        program = GLES20.glCreateProgram().also {
            GLES20.glAttachShader(it, vertexShader)
            GLES20.glAttachShader(it, fragmentShader)
            GLES20.glLinkProgram(it)

            // H2: 프로그램 링크 상태 확인
            val linkStatus = IntArray(1)
            GLES20.glGetProgramiv(it, GLES20.GL_LINK_STATUS, linkStatus, 0)
            if (linkStatus[0] == 0) {
                val log = GLES20.glGetProgramInfoLog(it)
                GLES20.glDeleteProgram(it)
                throw RuntimeException("Program link failed: $log")
            }
        }

        positionAttrib = GLES20.glGetAttribLocation(program, "a_Position")
        mvpMatrixUniform = GLES20.glGetUniformLocation(program, "u_MvpMatrix")
        colorUniform = GLES20.glGetUniformLocation(program, "u_Color")
        pointSizeUniform = GLES20.glGetUniformLocation(program, "u_PointSize")
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

        GLES20.glUseProgram(program)
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
        lineWidth: Float = 60f
    ) {
        Matrix.multiplyMM(mvpMatrix, 0, projMatrix, 0, viewMatrix, 0)

        lineBuffer.clear()
        lineBuffer.put(p1, 0, 3)
        lineBuffer.put(p2, 0, 3)
        lineBuffer.position(0)

        GLES20.glUseProgram(program)
        GLES20.glUniformMatrix4fv(mvpMatrixUniform, 1, false, mvpMatrix, 0)
        GLES20.glUniform4fv(colorUniform, 1, color, 0)
        GLES20.glLineWidth(lineWidth)

        GLES20.glEnableVertexAttribArray(positionAttrib)
        GLES20.glVertexAttribPointer(positionAttrib, 3, GLES20.GL_FLOAT, false, 0, lineBuffer)
        GLES20.glDrawArrays(GLES20.GL_LINES, 0, 2)
        GLES20.glDisableVertexAttribArray(positionAttrib)
    }

    private fun allocateBuffer(floatCount: Int): FloatBuffer {
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

    companion object {
        private const val VERTEX_SHADER = """
            uniform mat4 u_MvpMatrix;
            uniform float u_PointSize;
            attribute vec4 a_Position;
            void main() {
                gl_Position = u_MvpMatrix * a_Position;
                gl_PointSize = u_PointSize;
            }
        """

        private const val FRAGMENT_SHADER = """
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
    }
}
