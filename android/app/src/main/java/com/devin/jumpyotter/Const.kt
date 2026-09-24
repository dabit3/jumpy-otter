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

    // arcade milestone banner cadence (rows)
    const val milestoneEvery = 25

    // forward hops landing within this window of the previous one chain a combo
    const val comboWindow = 0.6f
    // every N combo hops pays out a bonus creatine
    const val comboBonusEvery = 10
    const val comboShowAt = 3
    // clearance past a car's bumper that still counts as a close call when leaving a lane
    const val closeCallMargin = 0.55f
    const val leaderboardSize = 5
}

/** Unlockable otter colourways, earned with lifetime creatine. */
class Skin(val name: String, val fur: Rgb, val dark: Rgb, val belly: Rgb, val unlockAt: Int) {
    /** Fur colour, or the lighter belly colour when the fur is too dark to read on navy HUD cards. */
    val labelColor: Rgb get() = if (0.299f * fur.r + 0.587f * fur.g + 0.114f * fur.b < 0.5f) belly else fur
}

object Skins {
    val all: List<Skin> by lazy {
        listOf(
            Skin("CLASSIC", Palette.otter, Palette.otterDark, Palette.otterCream, 0),
            Skin("ARCTIC", Rgb(0.94f, 0.96f, 0.99f), Rgb(0.74f, 0.82f, 0.92f), Rgb(0.62f, 0.86f, 1.00f), 10),
            Skin("GOLDEN", Rgb(1.00f, 0.84f, 0.24f), Rgb(0.88f, 0.64f, 0.10f), Rgb(1.00f, 0.97f, 0.80f), 25),
            Skin("MIDNIGHT", Rgb(0.38f, 0.34f, 0.62f), Rgb(0.24f, 0.21f, 0.44f), Rgb(0.45f, 0.95f, 0.90f), 50),
            Skin("CHERRY", Rgb(1.00f, 0.55f, 0.68f), Rgb(0.86f, 0.36f, 0.52f), Rgb(1.00f, 0.93f, 0.95f), 100),
        )
    }

    fun isUnlocked(index: Int, total: Int): Boolean = index in all.indices && total >= all[index].unlockAt

    fun next(total: Int): Skin? = all.firstOrNull { it.unlockAt > total }
}

enum class Haptic { LIGHT, MEDIUM, HEAVY, SUCCESS }

/** Arcade rank awarded on the game-over card. */
object Rank {
    fun title(score: Int): String = when {
        score < 10 -> "ROOKIE"
        score < 25 -> "HOPPER"
        score < 50 -> "PRO"
        score < 100 -> "LEGEND"
        else -> "OTTERLORD"
    }

    fun color(score: Int): Rgb = when {
        score < 10 -> Palette.hudSilver
        score < 25 -> Palette.leaf
        score < 50 -> Palette.window
        score < 100 -> Palette.accentGold
        else -> Palette.hotOrange
    }
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
    val grassLight = Rgb(0.52f, 0.80f, 0.38f)
    val grassDark = Rgb(0.45f, 0.73f, 0.33f)
    val grassSide = Rgb(0.30f, 0.52f, 0.27f)
    val grassTuft = Rgb(0.36f, 0.66f, 0.28f)
    val road = Rgb(0.22f, 0.23f, 0.28f)
    val water = Rgb(0.20f, 0.62f, 0.86f)
    val riverBed = Rgb(0.12f, 0.38f, 0.58f)
    val waterFoam = Rgb(0.80f, 0.93f, 0.99f)
    val flowerColors = listOf(
        Rgb(0.98f, 0.45f, 0.62f),
        Rgb(1.00f, 0.86f, 0.25f),
        Rgb(0.98f, 0.98f, 0.98f),
        Rgb(0.60f, 0.55f, 0.95f),
    )
    // HUD / arcade chrome
    val hudNavy = Rgb(0.07f, 0.09f, 0.20f)
    val hudInk = Rgb(0.10f, 0.07f, 0.16f)
    val hudCream = Rgb(1.00f, 0.96f, 0.86f)
    val hudSilver = Rgb(0.80f, 0.84f, 0.90f)
    val hotOrange = Rgb(1.00f, 0.45f, 0.15f)
    val dangerRed = Rgb(0.95f, 0.20f, 0.22f)
    val shadow = Rgb(0.08f, 0.14f, 0.10f)
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
    val sky = Rgb(0.53f, 0.78f, 0.95f)
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
