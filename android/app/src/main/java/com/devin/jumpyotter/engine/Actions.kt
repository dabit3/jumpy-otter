package com.devin.jumpyotter.engine

import kotlin.math.PI

enum class Timing {
    LINEAR, EASE_IN, EASE_OUT, EASE_IN_OUT;

    fun apply(t: Float): Float = when (this) {
        LINEAR -> t
        EASE_IN -> t * t
        EASE_OUT -> 1f - (1f - t) * (1f - t)
        EASE_IN_OUT -> if (t < 0.5f) 2f * t * t else 1f - 2f * (1f - t) * (1f - t)
    }
}

/** SceneKit-style action. `step` returns true once the action has finished. */
abstract class Action {
    var timing = Timing.LINEAR
    abstract fun step(node: Node, dt: Float): Boolean
    open fun reset() {}
}

/** Duration-based action that applies a progress delta each frame so concurrent moves compose. */
abstract class IntervalAction(val duration: Float) : Action() {
    private var elapsed = 0f
    private var prevProgress = 0f
    private var started = false

    override fun reset() {
        elapsed = 0f
        prevProgress = 0f
        started = false
    }

    protected abstract fun begin(node: Node)
    protected abstract fun apply(node: Node, prev: Float, cur: Float)

    override fun step(node: Node, dt: Float): Boolean {
        if (!started) { started = true; begin(node) }
        elapsed += dt
        val done = duration <= 0f || elapsed >= duration
        val cur = if (done) 1f else timing.apply(elapsed / duration)
        apply(node, prevProgress, cur)
        prevProgress = cur
        return done
    }
}

class MoveBy(val dx: Float, val dy: Float, val dz: Float, duration: Float) : IntervalAction(duration) {
    override fun begin(node: Node) {}
    override fun apply(node: Node, prev: Float, cur: Float) {
        val d = cur - prev
        node.position.x += dx * d
        node.position.y += dy * d
        node.position.z += dz * d
    }
}

class MoveTo(val tx: Float, val ty: Float, val tz: Float, duration: Float) : IntervalAction(duration) {
    private var dx = 0f; private var dy = 0f; private var dz = 0f
    override fun begin(node: Node) {
        dx = tx - node.position.x; dy = ty - node.position.y; dz = tz - node.position.z
    }
    override fun apply(node: Node, prev: Float, cur: Float) {
        val d = cur - prev
        node.position.x += dx * d
        node.position.y += dy * d
        node.position.z += dz * d
    }
}

class RotateTo(val rx: Float, val ry: Float, val rz: Float, duration: Float, val shortest: Boolean = false) : IntervalAction(duration) {
    private var dx = 0f; private var dy = 0f; private var dz = 0f
    private fun delta(from: Float, to: Float): Float {
        var d = to - from
        if (shortest) {
            val twoPi = (2 * PI).toFloat()
            while (d > PI) d -= twoPi
            while (d < -PI) d += twoPi
        }
        return d
    }
    override fun begin(node: Node) {
        dx = delta(node.eulerAngles.x, rx); dy = delta(node.eulerAngles.y, ry); dz = delta(node.eulerAngles.z, rz)
    }
    override fun apply(node: Node, prev: Float, cur: Float) {
        val d = cur - prev
        node.eulerAngles.x += dx * d
        node.eulerAngles.y += dy * d
        node.eulerAngles.z += dz * d
    }
}

class RotateBy(val ry: Float, duration: Float) : IntervalAction(duration) {
    override fun begin(node: Node) {}
    override fun apply(node: Node, prev: Float, cur: Float) {
        node.eulerAngles.y += ry * (cur - prev)
    }
}

class ScaleTo(val target: Float, duration: Float) : IntervalAction(duration) {
    private var sx = 0f; private var sy = 0f; private var sz = 0f
    override fun begin(node: Node) {
        sx = node.scale.x; sy = node.scale.y; sz = node.scale.z
    }
    override fun apply(node: Node, prev: Float, cur: Float) {
        node.scale.x = sx + (target - sx) * cur
        node.scale.y = sy + (target - sy) * cur
        node.scale.z = sz + (target - sz) * cur
    }
}

class FadeOut(duration: Float) : IntervalAction(duration) {
    private var start = 1f
    override fun begin(node: Node) { start = node.opacity }
    override fun apply(node: Node, prev: Float, cur: Float) {
        node.opacity = start * (1f - cur)
    }
}

class Wait(duration: Float) : IntervalAction(duration) {
    override fun begin(node: Node) {}
    override fun apply(node: Node, prev: Float, cur: Float) {}
}

class Run(val block: () -> Unit) : Action() {
    override fun step(node: Node, dt: Float): Boolean { block(); return true }
}

class RemoveFromParent : Action() {
    override fun step(node: Node, dt: Float): Boolean { node.removeFromParent(); return true }
}

class Sequence(vararg val actions: Action) : Action() {
    private var index = 0
    override fun reset() { index = 0; actions.forEach { it.reset() } }
    override fun step(node: Node, dt: Float): Boolean {
        var remaining = dt
        while (index < actions.size) {
            if (!actions[index].step(node, remaining)) return false
            index++
            remaining = 0f
        }
        return true
    }
}

class Group(vararg val actions: Action) : Action() {
    private val done = BooleanArray(actions.size)
    override fun reset() { done.fill(false); actions.forEach { it.reset() } }
    override fun step(node: Node, dt: Float): Boolean {
        var all = true
        for (i in actions.indices) {
            if (!done[i]) {
                if (actions[i].step(node, dt)) done[i] = true else all = false
            }
        }
        return all
    }
}

class RepeatForever(val action: Action) : Action() {
    override fun reset() { action.reset() }
    override fun step(node: Node, dt: Float): Boolean {
        if (action.step(node, dt)) action.reset()
        return false
    }
}
