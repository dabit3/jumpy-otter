package com.devin.jumpyotter.engine

import android.opengl.Matrix

class Vec3(var x: Float = 0f, var y: Float = 0f, var z: Float = 0f) {
    fun set(x: Float, y: Float, z: Float): Vec3 { this.x = x; this.y = y; this.z = z; return this }
    fun set(o: Vec3): Vec3 = set(o.x, o.y, o.z)
    fun copy() = Vec3(x, y, z)
}

/** Minimal scene-graph node: TRS transform, optional mesh, opacity, emissive tint and actions. */
open class Node(var mesh: Mesh? = null) {
    var name: String? = null
    val position = Vec3()
    val eulerAngles = Vec3()  // radians, applied as Y (yaw) then X then Z
    val scale = Vec3(1f, 1f, 1f)
    var opacity = 1f
    var hidden = false
    var emissive: FloatArray? = null

    var parent: Node? = null
        private set
    val children = ArrayList<Node>()
    val actions = ArrayList<Action>()

    val worldMatrix = FloatArray(16)
    private val local = FloatArray(16)

    fun addChild(child: Node) {
        child.parent?.children?.remove(child)
        child.parent = this
        children.add(child)
    }

    fun removeFromParent() {
        parent?.children?.remove(this)
        parent = null
    }

    fun childNamed(n: String): Node? {
        for (c in children) {
            if (c.name == n) return c
            c.childNamed(n)?.let { return it }
        }
        return null
    }

    fun runAction(action: Action, completion: (() -> Unit)? = null) {
        action.reset()
        actions.add(if (completion == null) action else Sequence(action, Run(completion)))
    }

    fun removeAllActions() = actions.clear()

    fun updateActions(dt: Float) {
        if (actions.isNotEmpty()) {
            val snapshot = actions.toList()
            for (a in snapshot) {
                if (a.step(this, dt)) actions.remove(a)
            }
        }
        for (c in children.toList()) c.updateActions(dt)
    }

    fun computeLocal(): FloatArray {
        Matrix.setIdentityM(local, 0)
        Matrix.translateM(local, 0, position.x, position.y, position.z)
        if (eulerAngles.y != 0f) Matrix.rotateM(local, 0, Math.toDegrees(eulerAngles.y.toDouble()).toFloat(), 0f, 1f, 0f)
        if (eulerAngles.x != 0f) Matrix.rotateM(local, 0, Math.toDegrees(eulerAngles.x.toDouble()).toFloat(), 1f, 0f, 0f)
        if (eulerAngles.z != 0f) Matrix.rotateM(local, 0, Math.toDegrees(eulerAngles.z.toDouble()).toFloat(), 0f, 0f, 1f)
        if (scale.x != 1f || scale.y != 1f || scale.z != 1f) Matrix.scaleM(local, 0, scale.x, scale.y, scale.z)
        return local
    }

    fun disposeMeshes(gen: Int) {
        mesh?.dispose(gen)
        for (c in children) c.disposeMeshes(gen)
    }
}
