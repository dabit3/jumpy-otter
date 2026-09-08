package com.devin.jumpyotter.engine

import android.opengl.GLES20
import android.opengl.Matrix
import com.devin.jumpyotter.Rgb
import kotlin.math.sqrt

/**
 * Tiny GLES2 forward renderer: one flat-shaded program (ambient + directional
 * lambert), orthographic camera, opaque pass followed by a sorted transparent pass.
 */
class SceneRenderer {
    val root = Node()
    var background = Rgb(0.66f, 0.80f, 0.84f)

    // camera (orthographic, looks from `eye` toward `target`)
    val eye = Vec3(-6.5f, 10.5f, -7f)
    val target = Vec3()
    var orthoScale = 7.5f

    // light direction pointing *toward* the light
    var lightDir = floatArrayOf(-0.209f, 0.935f, 0.287f)
    var ambient = 0.55f
    var diffuse = 0.75f

    var contextGen = 0
        private set

    private var program = 0
    private var aPos = 0
    private var aNormal = 0
    private var aColor = 0
    private var uMvp = 0
    private var uModel = 0
    private var uLight = 0
    private var uAmbient = 0
    private var uDiffuse = 0
    private var uAlpha = 0
    private var uEmissive = 0

    private val view = FloatArray(16)
    private val proj = FloatArray(16)
    private val viewProj = FloatArray(16)
    private val mvp = FloatArray(16)
    private var aspect = 1f

    private class DrawItem(val node: Node, val opacity: Float, val depth: Float)
    private val opaque = ArrayList<DrawItem>(512)
    private val transparent = ArrayList<DrawItem>(64)
    private val noEmissive = floatArrayOf(0f, 0f, 0f)

    fun onSurfaceCreated() {
        contextGen++
        program = buildProgram()
        aPos = GLES20.glGetAttribLocation(program, "a_pos")
        aNormal = GLES20.glGetAttribLocation(program, "a_normal")
        aColor = GLES20.glGetAttribLocation(program, "a_color")
        uMvp = GLES20.glGetUniformLocation(program, "u_mvp")
        uModel = GLES20.glGetUniformLocation(program, "u_model")
        uLight = GLES20.glGetUniformLocation(program, "u_lightDir")
        uAmbient = GLES20.glGetUniformLocation(program, "u_ambient")
        uDiffuse = GLES20.glGetUniformLocation(program, "u_diffuse")
        uAlpha = GLES20.glGetUniformLocation(program, "u_alpha")
        uEmissive = GLES20.glGetUniformLocation(program, "u_emissive")
        GLES20.glEnable(GLES20.GL_DEPTH_TEST)
        GLES20.glEnable(GLES20.GL_CULL_FACE)
        GLES20.glCullFace(GLES20.GL_BACK)
    }

    fun onSurfaceChanged(width: Int, height: Int) {
        GLES20.glViewport(0, 0, width, height)
        aspect = width.toFloat() / height.toFloat()
    }

    fun draw() {
        GLES20.glClearColor(background.r, background.g, background.b, 1f)
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT or GLES20.GL_DEPTH_BUFFER_BIT)

        Matrix.setLookAtM(view, 0, eye.x, eye.y, eye.z, target.x, target.y, target.z, 0f, 1f, 0f)
        Matrix.orthoM(proj, 0, -orthoScale * aspect, orthoScale * aspect, -orthoScale, orthoScale, 0.1f, 100f)
        Matrix.multiplyMM(viewProj, 0, proj, 0, view, 0)

        opaque.clear()
        transparent.clear()
        Matrix.setIdentityM(root.worldMatrix, 0)
        for (c in root.children) collect(c, root.worldMatrix, 1f)

        GLES20.glUseProgram(program)
        GLES20.glUniform3fv(uLight, 1, normalized(lightDir), 0)
        GLES20.glUniform1f(uAmbient, ambient)
        GLES20.glUniform1f(uDiffuse, diffuse)
        GLES20.glEnableVertexAttribArray(aPos)
        GLES20.glEnableVertexAttribArray(aNormal)
        GLES20.glEnableVertexAttribArray(aColor)

        GLES20.glDisable(GLES20.GL_BLEND)
        GLES20.glDepthMask(true)
        for (item in opaque) drawItem(item)

        if (transparent.isNotEmpty()) {
            transparent.sortByDescending { it.depth }
            GLES20.glEnable(GLES20.GL_BLEND)
            GLES20.glBlendFunc(GLES20.GL_SRC_ALPHA, GLES20.GL_ONE_MINUS_SRC_ALPHA)
            GLES20.glDepthMask(false)
            for (item in transparent) drawItem(item)
            GLES20.glDepthMask(true)
            GLES20.glDisable(GLES20.GL_BLEND)
        }

        GLES20.glDisableVertexAttribArray(aPos)
        GLES20.glDisableVertexAttribArray(aNormal)
        GLES20.glDisableVertexAttribArray(aColor)
    }

    private fun collect(node: Node, parentWorld: FloatArray, parentOpacity: Float) {
        if (node.hidden) return
        Matrix.multiplyMM(node.worldMatrix, 0, parentWorld, 0, node.computeLocal(), 0)
        val opacity = parentOpacity * node.opacity
        if (node.mesh != null && opacity > 0.001f) {
            // depth along the view direction for transparent sorting
            val wx = node.worldMatrix[12]; val wy = node.worldMatrix[13]; val wz = node.worldMatrix[14]
            val depth = (wx - eye.x) * (target.x - eye.x) + (wy - eye.y) * (target.y - eye.y) + (wz - eye.z) * (target.z - eye.z)
            val item = DrawItem(node, opacity, depth)
            if (opacity < 0.999f) transparent.add(item) else opaque.add(item)
        }
        for (c in node.children) collect(c, node.worldMatrix, opacity)
    }

    private fun drawItem(item: DrawItem) {
        val mesh = item.node.mesh ?: return
        Matrix.multiplyMM(mvp, 0, viewProj, 0, item.node.worldMatrix, 0)
        GLES20.glUniformMatrix4fv(uMvp, 1, false, mvp, 0)
        GLES20.glUniformMatrix4fv(uModel, 1, false, item.node.worldMatrix, 0)
        GLES20.glUniform1f(uAlpha, item.opacity)
        GLES20.glUniform3fv(uEmissive, 1, item.node.emissive ?: noEmissive, 0)
        mesh.bind(contextGen)
        GLES20.glVertexAttribPointer(aPos, 3, GLES20.GL_FLOAT, false, Mesh.STRIDE, 0)
        GLES20.glVertexAttribPointer(aNormal, 3, GLES20.GL_FLOAT, false, Mesh.STRIDE, 12)
        GLES20.glVertexAttribPointer(aColor, 3, GLES20.GL_FLOAT, false, Mesh.STRIDE, 24)
        GLES20.glDrawElements(GLES20.GL_TRIANGLES, mesh.indexCount, GLES20.GL_UNSIGNED_SHORT, 0)
    }

    private fun normalized(v: FloatArray): FloatArray {
        val len = sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2])
        return floatArrayOf(v[0] / len, v[1] / len, v[2] / len)
    }

    private fun buildProgram(): Int {
        val vs = compile(GLES20.GL_VERTEX_SHADER, VERTEX_SHADER)
        val fs = compile(GLES20.GL_FRAGMENT_SHADER, FRAGMENT_SHADER)
        val p = GLES20.glCreateProgram()
        GLES20.glAttachShader(p, vs)
        GLES20.glAttachShader(p, fs)
        GLES20.glLinkProgram(p)
        val status = IntArray(1)
        GLES20.glGetProgramiv(p, GLES20.GL_LINK_STATUS, status, 0)
        check(status[0] != 0) { "program link failed: " + GLES20.glGetProgramInfoLog(p) }
        return p
    }

    private fun compile(type: Int, src: String): Int {
        val s = GLES20.glCreateShader(type)
        GLES20.glShaderSource(s, src)
        GLES20.glCompileShader(s)
        val status = IntArray(1)
        GLES20.glGetShaderiv(s, GLES20.GL_COMPILE_STATUS, status, 0)
        check(status[0] != 0) { "shader compile failed: " + GLES20.glGetShaderInfoLog(s) }
        return s
    }

    companion object {
        private const val VERTEX_SHADER = """
            uniform mat4 u_mvp;
            uniform mat4 u_model;
            uniform vec3 u_lightDir;
            uniform float u_ambient;
            uniform float u_diffuse;
            uniform vec3 u_emissive;
            attribute vec3 a_pos;
            attribute vec3 a_normal;
            attribute vec3 a_color;
            varying vec3 v_color;
            void main() {
                vec3 n = normalize(mat3(u_model[0].xyz, u_model[1].xyz, u_model[2].xyz) * a_normal);
                float ndl = max(dot(n, u_lightDir), 0.0);
                v_color = a_color * (u_ambient + u_diffuse * ndl) + u_emissive;
                gl_Position = u_mvp * vec4(a_pos, 1.0);
            }
        """

        private const val FRAGMENT_SHADER = """
            precision mediump float;
            uniform float u_alpha;
            varying vec3 v_color;
            void main() {
                gl_FragColor = vec4(v_color, u_alpha);
            }
        """
    }
}
