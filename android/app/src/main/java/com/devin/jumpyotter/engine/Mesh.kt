package com.devin.jumpyotter.engine

import android.opengl.GLES20
import android.opengl.Matrix
import com.devin.jumpyotter.Rgb
import java.nio.ByteBuffer
import java.nio.ByteOrder

/** Interleaved vertex data: position(3) normal(3) color(3). */
class Mesh(private val vertices: FloatArray, private val indices: ShortArray) {
    val indexCount = indices.size
    private var vbo = 0
    private var ibo = 0
    private var uploadedGen = -1

    fun bind(gen: Int) {
        if (uploadedGen != gen) upload(gen)
        GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, vbo)
        GLES20.glBindBuffer(GLES20.GL_ELEMENT_ARRAY_BUFFER, ibo)
    }

    private fun upload(gen: Int) {
        val ids = IntArray(2)
        GLES20.glGenBuffers(2, ids, 0)
        vbo = ids[0]
        ibo = ids[1]
        val vb = ByteBuffer.allocateDirect(vertices.size * 4).order(ByteOrder.nativeOrder()).asFloatBuffer()
        vb.put(vertices).position(0)
        GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, vbo)
        GLES20.glBufferData(GLES20.GL_ARRAY_BUFFER, vertices.size * 4, vb, GLES20.GL_STATIC_DRAW)
        val ib = ByteBuffer.allocateDirect(indices.size * 2).order(ByteOrder.nativeOrder()).asShortBuffer()
        ib.put(indices).position(0)
        GLES20.glBindBuffer(GLES20.GL_ELEMENT_ARRAY_BUFFER, ibo)
        GLES20.glBufferData(GLES20.GL_ELEMENT_ARRAY_BUFFER, indices.size * 2, ib, GLES20.GL_STATIC_DRAW)
        uploadedGen = gen
    }

    fun dispose(gen: Int) {
        if (uploadedGen == gen && vbo != 0) {
            GLES20.glDeleteBuffers(2, intArrayOf(vbo, ibo), 0)
        }
        vbo = 0
        ibo = 0
        uploadedGen = -1
    }

    companion object {
        const val STRIDE = 9 * 4
    }
}

/** Accumulates axis-aligned (optionally rotated) boxes into a single mesh. */
class MeshBuilder {
    private val verts = ArrayList<Float>(9 * 24 * 16)
    private val idx = ArrayList<Short>(36 * 16)
    private val tmpM = FloatArray(16)
    private val tmpR = FloatArray(16)
    private val tmpV = FloatArray(4)
    private val tmpN = FloatArray(4)
    private val outV = FloatArray(4)
    private val outN = FloatArray(4)

    // cursor transform applied to every box (used when merging models into a row mesh)
    private var offX = 0f
    private var offY = 0f
    private var offZ = 0f
    private var cursorScale = 1f
    private var cursorYaw = 0f

    fun withOffset(x: Float, y: Float, z: Float, scale: Float = 1f, yaw: Float = 0f, block: MeshBuilder.() -> Unit) {
        val px = offX; val py = offY; val pz = offZ; val ps = cursorScale; val pyaw = cursorYaw
        offX = x; offY = y; offZ = z; cursorScale = scale; cursorYaw = yaw
        block()
        offX = px; offY = py; offZ = pz; cursorScale = ps; cursorYaw = pyaw
    }

    val isEmpty get() = idx.isEmpty()

    fun box(
        w: Float, h: Float, l: Float, color: Rgb,
        x: Float = 0f, y: Float = 0f, z: Float = 0f,
        rotY: Float = 0f, rotZ: Float = 0f,
    ) {
        Matrix.setIdentityM(tmpM, 0)
        Matrix.translateM(tmpM, 0, offX, offY, offZ)
        if (cursorYaw != 0f) Matrix.rotateM(tmpM, 0, Math.toDegrees(cursorYaw.toDouble()).toFloat(), 0f, 1f, 0f)
        Matrix.scaleM(tmpM, 0, cursorScale, cursorScale, cursorScale)
        Matrix.translateM(tmpM, 0, x, y, z)
        if (rotY != 0f) Matrix.rotateM(tmpM, 0, Math.toDegrees(rotY.toDouble()).toFloat(), 0f, 1f, 0f)
        if (rotZ != 0f) Matrix.rotateM(tmpM, 0, Math.toDegrees(rotZ.toDouble()).toFloat(), 0f, 0f, 1f)
        // rotation-only matrix for normals (uniform scale keeps directions)
        Matrix.setIdentityM(tmpR, 0)
        if (cursorYaw != 0f) Matrix.rotateM(tmpR, 0, Math.toDegrees(cursorYaw.toDouble()).toFloat(), 0f, 1f, 0f)
        if (rotY != 0f) Matrix.rotateM(tmpR, 0, Math.toDegrees(rotY.toDouble()).toFloat(), 0f, 1f, 0f)
        if (rotZ != 0f) Matrix.rotateM(tmpR, 0, Math.toDegrees(rotZ.toDouble()).toFloat(), 0f, 0f, 1f)

        val hw = w / 2; val hh = h / 2; val hl = l / 2
        for (f in FACES) {
            val base = (verts.size / 9).toShort()
            for (c in 0 until 4) {
                tmpV[0] = f.corners[c * 3] * hw
                tmpV[1] = f.corners[c * 3 + 1] * hh
                tmpV[2] = f.corners[c * 3 + 2] * hl
                tmpV[3] = 1f
                Matrix.multiplyMV(outV, 0, tmpM, 0, tmpV, 0)
                tmpN[0] = f.nx; tmpN[1] = f.ny; tmpN[2] = f.nz; tmpN[3] = 0f
                Matrix.multiplyMV(outN, 0, tmpR, 0, tmpN, 0)
                verts.add(outV[0]); verts.add(outV[1]); verts.add(outV[2])
                verts.add(outN[0]); verts.add(outN[1]); verts.add(outN[2])
                verts.add(color.r); verts.add(color.g); verts.add(color.b)
            }
            idx.add(base); idx.add((base + 1).toShort()); idx.add((base + 2).toShort())
            idx.add(base); idx.add((base + 2).toShort()); idx.add((base + 3).toShort())
        }
    }

    fun build(): Mesh {
        check(verts.size / 9 <= 65535) { "mesh too large for 16-bit indices" }
        return Mesh(verts.toFloatArray(), idx.toShortArray())
    }

    private class Face(val nx: Float, val ny: Float, val nz: Float, val corners: FloatArray)

    companion object {
        // counter-clockwise when viewed from outside
        private val FACES = arrayOf(
            Face(0f, 0f, 1f, floatArrayOf(-1f, -1f, 1f, 1f, -1f, 1f, 1f, 1f, 1f, -1f, 1f, 1f)),      // +Z
            Face(0f, 0f, -1f, floatArrayOf(1f, -1f, -1f, -1f, -1f, -1f, -1f, 1f, -1f, 1f, 1f, -1f)),  // -Z
            Face(1f, 0f, 0f, floatArrayOf(1f, -1f, 1f, 1f, -1f, -1f, 1f, 1f, -1f, 1f, 1f, 1f)),      // +X
            Face(-1f, 0f, 0f, floatArrayOf(-1f, -1f, -1f, -1f, -1f, 1f, -1f, 1f, 1f, -1f, 1f, -1f)),  // -X
            Face(0f, 1f, 0f, floatArrayOf(-1f, 1f, 1f, 1f, 1f, 1f, 1f, 1f, -1f, -1f, 1f, -1f)),      // +Y
            Face(0f, -1f, 0f, floatArrayOf(-1f, -1f, -1f, 1f, -1f, -1f, 1f, -1f, 1f, -1f, -1f, 1f)),  // -Y
        )

        fun single(w: Float, h: Float, l: Float, color: Rgb): Mesh =
            MeshBuilder().apply { box(w, h, l, color) }.build()
    }
}
