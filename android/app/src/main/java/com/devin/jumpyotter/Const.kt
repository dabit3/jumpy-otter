package com.devin.jumpyotter

import kotlin.math.PI
import kotlin.random.Random

object K {
    // Playable lateral bounds (tile columns)
    const val minCol = -4
    const val maxCol = 4
    // Visual row width extends beyond playable area
    const val visualHalfWidth = 16f
    // Moving objects wrap within this half-length
    const val wrapHalf = 13f

    const val hopDuration = 0.135f
    const val hopHeight = 0.45f

    const val rowsAhead = 22
    const val rowsBehindKeep = 16

    const val cameraAutoAdvance = 0.35f
    const val cameraBehindLimit = 7.5f
    const val idleEagleSeconds = 6.0f

    const val playerHalfWidth = 0.30f
    const val trainPlayerHalfWidth = 0.12f
    const val trainCollisionInset = 0.22f
    const val trainRowHalfDepth = 0.30f

    // multiplayer garbage: road traffic speed surge on rivals
    const val garbageSpeedBoost = 1.7f
    const val garbageBoostSeconds = 4.0f
}

class Rgb(val r: Float, val g: Float, val b: Float) {
    fun toArgb(alpha: Float = 1f): Int {
        fun c(v: Float) = (v.coerceIn(0f, 1f) * 255f + 0.5f).toInt()
        return (c(alpha) shl 24) or (c(r) shl 16) or (c(g) shl 8) or c(b)
    }

    companion object {
        fun gray(w: Float) = Rgb(w, w, w)
    }
}

object Palette {
    val grassLight = Rgb(0.46f, 0.72f, 0.38f)
    val grassDark = Rgb(0.40f, 0.66f, 0.34f)
    val grassSide = Rgb(0.31f, 0.52f, 0.30f)
    val road = Rgb(0.25f, 0.27f, 0.30f)
    val water = Rgb(0.24f, 0.58f, 0.72f)
    val riverBed = Rgb(0.16f, 0.40f, 0.52f)
    val sidewalk = Rgb(0.72f, 0.70f, 0.66f)
    val curb = Rgb(0.88f, 0.86f, 0.80f)
    val railBed = Rgb(0.48f, 0.46f, 0.42f)
    val railTie = Rgb(0.35f, 0.26f, 0.18f)
    val railSteel = Rgb(0.65f, 0.66f, 0.70f)
    val trunk = Rgb(0.55f, 0.38f, 0.22f)
    val leaf = Rgb(0.30f, 0.68f, 0.29f)
    val leafDark = Rgb(0.24f, 0.58f, 0.24f)
    val logBrown = Rgb(0.62f, 0.42f, 0.24f)
    val logEnd = Rgb(0.78f, 0.60f, 0.38f)
    val white = Rgb(0.98f, 0.98f, 0.98f)
    val whiteShade = Rgb(0.88f, 0.89f, 0.92f)
    val otter = Rgb(1.00f, 0.65f, 0.27f)
    val otterDark = Rgb(0.90f, 0.54f, 0.16f)
    val otterCream = Rgb(0.98f, 0.97f, 0.93f)
    val beakOrange = Rgb(0.95f, 0.58f, 0.13f)
    val black = Rgb(0.13f, 0.13f, 0.16f)
    val accentGold = Rgb(1.00f, 0.84f, 0.20f)
    val sky = Rgb(0.66f, 0.80f, 0.84f)
    val wheel = Rgb(0.15f, 0.15f, 0.18f)
    val window = Rgb(0.55f, 0.80f, 0.95f)
    val cableRed = Rgb(0.72f, 0.13f, 0.12f)
    val cableCream = Rgb(0.94f, 0.86f, 0.68f)
    val houseTrim = Rgb(0.96f, 0.91f, 0.81f)
    val houseColors = listOf(
        Rgb(0.40f, 0.60f, 0.68f),
        Rgb(0.82f, 0.45f, 0.37f),
        Rgb(0.86f, 0.65f, 0.27f),
        Rgb(0.46f, 0.64f, 0.50f),
        Rgb(0.59f, 0.51f, 0.68f),
    )
    val trainBody = Rgb(0.75f, 0.22f, 0.20f)
    val trainCar = Rgb(0.45f, 0.48f, 0.55f)
    val eagleBrown = Rgb(0.42f, 0.29f, 0.18f)
    val rivalColors = listOf(
        Rgb(1.00f, 0.65f, 0.27f),  // P1 orange
        Rgb(0.35f, 0.55f, 0.90f),  // P2 blue
        Rgb(0.60f, 0.40f, 0.85f),  // P3 purple
        Rgb(0.28f, 0.75f, 0.60f),  // P4 teal
    )
    fun rivalColor(id: Int): Rgb = rivalColors[((id % rivalColors.size) + rivalColors.size) % rivalColors.size]
    val carColors = listOf(
        Rgb(0.90f, 0.30f, 0.25f),
        Rgb(0.98f, 0.65f, 0.15f),
        Rgb(0.35f, 0.55f, 0.90f),
        Rgb(0.60f, 0.40f, 0.85f),
        Rgb(0.28f, 0.75f, 0.60f),
        Rgb(0.95f, 0.95f, 0.95f),
    )
}

/** World-space delta. Forward is +Z. With the camera at (-x, +y, -z), screen-right is world -X. */
enum class Dir(val dx: Int, val dz: Int, val yaw: Float) {
    FORWARD(0, 1, 0f),
    BACK(0, -1, PI.toFloat()),
    LEFT(1, 0, PI.toFloat() / 2),
    RIGHT(-1, 0, -PI.toFloat() / 2),
}

fun rand(lo: Float, hi: Float): Float = lo + Random.nextFloat() * (hi - lo)
fun rand01(): Float = Random.nextFloat()
fun randInt(lo: Int, hi: Int): Int = Random.nextInt(lo, hi + 1)
fun randBool(): Boolean = Random.nextBoolean()
