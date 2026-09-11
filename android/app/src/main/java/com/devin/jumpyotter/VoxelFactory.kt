package com.devin.jumpyotter

import com.devin.jumpyotter.engine.FadeTo
import com.devin.jumpyotter.engine.Group
import com.devin.jumpyotter.engine.MeshBuilder
import com.devin.jumpyotter.engine.MoveBy
import com.devin.jumpyotter.engine.Node
import com.devin.jumpyotter.engine.RepeatForever
import com.devin.jumpyotter.engine.RotateBy
import com.devin.jumpyotter.engine.RotateTo
import com.devin.jumpyotter.engine.ScaleTo
import com.devin.jumpyotter.engine.Sequence
import com.devin.jumpyotter.engine.Timing
import kotlin.math.PI

class Model(val node: Node, val halfLen: Float)

/** Builds all voxel-style models programmatically from boxes, mirroring the iOS VoxelFactory. */
object VoxelFactory {

    fun box(w: Float, h: Float, l: Float, color: Rgb, x: Float = 0f, y: Float = 0f, z: Float = 0f): Node {
        val n = Node(MeshBuilder.single(w, h, l, color))
        n.position.set(x, y, z)
        return n
    }

    private inline fun model(build: MeshBuilder.() -> Unit): Node = Node(MeshBuilder().apply(build).build())

    // MARK: - Wiskers (player), built facing +Z

    fun wiskersInto(mb: MeshBuilder) = with(mb) {
        // long tapered tail
        box(0.28f, 0.24f, 0.42f, Palette.otterDark, -0.04f, 0.25f, -0.37f)
        box(0.23f, 0.19f, 0.38f, Palette.otterDark, 0.05f, 0.18f, -0.69f, rotY = -0.28f)
        box(0.16f, 0.14f, 0.30f, Palette.otter, 0.16f, 0.13f, -0.96f, rotY = -0.38f)
        // body and cream belly
        box(0.50f, 0.52f, 0.48f, Palette.otterDark, 0f, 0.34f, 0f)
        box(0.34f, 0.34f, 0.07f, Palette.otterCream, 0f, 0.38f, 0.275f)
        // arms
        box(0.11f, 0.34f, 0.22f, Palette.otter, 0.29f, 0.39f, 0.03f)
        box(0.11f, 0.34f, 0.22f, Palette.otter, -0.29f, 0.39f, 0.03f)
        // feet
        box(0.22f, 0.15f, 0.30f, Palette.otter, 0.15f, 0.075f, 0.10f)
        box(0.22f, 0.15f, 0.30f, Palette.otter, -0.15f, 0.075f, 0.10f)
        // head and ears
        box(0.57f, 0.43f, 0.46f, Palette.otter, 0f, 0.76f, 0.05f)
        box(0.15f, 0.17f, 0.18f, Palette.otterDark, 0.31f, 0.86f, 0.01f)
        box(0.15f, 0.17f, 0.18f, Palette.otterDark, -0.31f, 0.86f, 0.01f)
        box(0.08f, 0.09f, 0.04f, Palette.otter, 0.315f, 0.86f, 0.115f)
        box(0.08f, 0.09f, 0.04f, Palette.otter, -0.315f, 0.86f, 0.115f)
        // eyes and highlights
        box(0.075f, 0.13f, 0.055f, Palette.black, 0.16f, 0.82f, 0.295f)
        box(0.075f, 0.13f, 0.055f, Palette.black, -0.16f, 0.82f, 0.295f)
        box(0.025f, 0.035f, 0.02f, Palette.white, 0.148f, 0.85f, 0.334f)
        box(0.025f, 0.035f, 0.02f, Palette.white, -0.172f, 0.85f, 0.334f)
        // white cheek muzzle and black nose
        box(0.24f, 0.17f, 0.07f, Palette.otterCream, 0.105f, 0.68f, 0.315f)
        box(0.24f, 0.17f, 0.07f, Palette.otterCream, -0.105f, 0.68f, 0.315f)
        box(0.15f, 0.105f, 0.09f, Palette.black, 0f, 0.735f, 0.375f)
        box(0.035f, 0.08f, 0.035f, Palette.black, 0f, 0.65f, 0.37f)
        // whiskers
        for (side in floatArrayOf(-1f, 1f)) {
            for ((offset, angle) in listOf(0.03f to 0.36f, -0.035f to -0.36f)) {
                box(0.18f, 0.024f, 0.025f, Palette.black, side * 0.25f, 0.66f + offset, 0.37f, rotZ = side * angle)
            }
        }
    }

    fun wiskers(): Node = model { wiskersInto(this) }.also { it.name = "wiskers" }

    // MARK: - Trees

    fun treeInto(mb: MeshBuilder, height: Int) = with(mb) {
        val trunkH = 0.35f
        box(0.26f, trunkH, 0.26f, Palette.trunk, 0f, trunkH / 2, 0f)
        var y = trunkH
        val layers = maxOf(1, height)
        for (i in 0 until layers) {
            val size = 0.95f - i * 0.18f
            val h = 0.34f
            val color = if (i % 2 == 0) Palette.leaf else Palette.leafDark
            box(size, h, size, color, 0f, y + h / 2, 0f)
            y += h
        }
    }

    fun paintedLadyInto(mb: MeshBuilder, color: Rgb) = with(mb) {
        box(0.92f, 0.16f, 0.86f, Palette.sidewalk, 0f, 0.08f, 0f)
        box(0.82f, 1.30f, 0.72f, color, 0f, 0.80f, 0f)
        box(0.88f, 0.09f, 0.78f, Palette.houseTrim, 0f, 1.43f, 0f)
        box(0.64f, 0.18f, 0.68f, color, 0f, 1.56f, 0f)
        box(0.46f, 0.16f, 0.58f, color, 0f, 1.72f, 0f)
        box(0.26f, 0.14f, 0.48f, color, 0f, 1.87f, 0f)
        for (x in floatArrayOf(-0.34f, 0.34f)) {
            box(0.055f, 1.22f, 0.05f, Palette.houseTrim, x, 0.82f, -0.385f)
        }
        box(0.40f, 0.62f, 0.14f, Palette.houseTrim, -0.11f, 0.91f, -0.41f)
        for (y in floatArrayOf(0.72f, 1.02f)) {
            for (x in floatArrayOf(-0.22f, 0f)) {
                box(0.13f, 0.20f, 0.035f, Palette.window, x, y, -0.50f)
            }
        }
        box(0.19f, 0.38f, 0.055f, Palette.cableRed, 0.22f, 0.37f, -0.40f)
        box(0.16f, 0.21f, 0.035f, Palette.window, -0.18f, 1.30f, -0.385f)
        box(0.16f, 0.21f, 0.035f, Palette.window, 0.16f, 1.30f, -0.385f)
        box(0.28f, 0.08f, 0.24f, Palette.houseTrim, 0.22f, 0.18f, -0.46f)
    }

    // MARK: - Vehicles (length axis = X, facing +X)

    fun car(color: Rgb): Model {
        val node = model {
            box(1.35f, 0.32f, 0.72f, color, 0f, 0.32f, 0f)
            // cabin with window band
            box(0.72f, 0.28f, 0.64f, Palette.window, -0.05f, 0.62f, 0f)
            box(0.30f, 0.30f, 0.66f, color, -0.38f, 0.63f, 0f)
            // headlights
            box(0.06f, 0.10f, 0.14f, Rgb.gray(1f), 0.68f, 0.36f, 0.22f)
            box(0.06f, 0.10f, 0.14f, Rgb.gray(1f), 0.68f, 0.36f, -0.22f)
            // wheels
            for (wx in floatArrayOf(0.42f, -0.42f)) {
                for (wz in floatArrayOf(0.34f, -0.34f)) {
                    box(0.26f, 0.26f, 0.14f, Palette.wheel, wx, 0.13f, wz)
                }
            }
        }
        return Model(node, 0.72f)
    }

    fun truck(): Model {
        val cabColor = Palette.carColors.random()
        val node = model {
            // cab
            box(0.62f, 0.62f, 0.78f, cabColor, 0.88f, 0.46f, 0f)
            box(0.30f, 0.24f, 0.70f, Palette.window, 1.0f, 0.72f, 0f)
            // trailer
            box(1.66f, 0.78f, 0.82f, Rgb.gray(0.92f), -0.35f, 0.58f, 0f)
            // wheels
            for (wx in floatArrayOf(1.0f, 0.2f, -0.9f)) {
                for (wz in floatArrayOf(0.36f, -0.36f)) {
                    box(0.28f, 0.28f, 0.14f, Palette.wheel, wx, 0.14f, wz)
                }
            }
        }
        return Model(node, 1.25f)
    }

    fun cableCar(): Model {
        val node = model {
            box(1.55f, 0.22f, 0.72f, Palette.cableRed, 0f, 0.27f, 0f)
            box(1.34f, 0.48f, 0.64f, Palette.cableCream, 0f, 0.60f, 0f)
            box(1.38f, 0.23f, 0.67f, Palette.black, 0f, 0.68f, 0f)
            var x = -0.55f
            while (x <= 0.55f + 1e-4f) {
                box(0.045f, 0.28f, 0.70f, Palette.cableRed, x, 0.68f, 0f)
                x += 0.28f
            }
            box(1.48f, 0.12f, 0.78f, Palette.cableCream, 0f, 0.93f, 0f)
            box(0.68f, 0.16f, 0.06f, Palette.cableRed, 0f, 0.98f, -0.43f)
            box(0.10f, 0.60f, 0.10f, Palette.black, 0f, 1.22f, 0f)
            box(0.52f, 0.06f, 0.06f, Palette.black, 0f, 1.51f, 0f)
            for (wx in floatArrayOf(0.53f, -0.53f)) {
                for (wz in floatArrayOf(0.34f, -0.34f)) {
                    box(0.24f, 0.24f, 0.13f, Palette.wheel, wx, 0.13f, wz)
                }
            }
        }
        return Model(node, 0.82f)
    }

    // MARK: - Ferries

    fun ferry(tiles: Int): Model {
        val len = tiles * 0.95f
        val node = model {
            box(len, 0.18f, 0.72f, Palette.houseTrim, 0f, 0.02f, 0f)
            box(len - 0.12f, 0.055f, 0.75f, Palette.cableRed, 0f, 0.015f, 0f)
            box(len - 0.30f, 0.055f, 0.58f, Palette.sidewalk, 0f, 0.09f, 0f)
            val cabinX = len / 2 - 0.34f
            box(0.38f, 0.24f, 0.48f, Palette.houseTrim, cabinX, 0.20f, 0f)
            box(0.26f, 0.11f, 0.51f, Palette.window, cabinX, 0.23f, 0f)
            box(0.46f, 0.06f, 0.56f, Palette.cableRed, cabinX, 0.35f, 0f)
        }
        return Model(node, len / 2)
    }

    // MARK: - Train

    fun train(carriages: Int): Model {
        val carLen = 1.95f
        val gap = 0.12f
        val total = carLen * (carriages + 1) + gap * carriages
        val node = model {
            withOffset(total / 2 - carLen / 2, 0f, 0f) {
                var x = 0f
                // engine
                box(carLen, 0.85f, 0.84f, Palette.trainBody, x, 0.55f, 0f)
                box(0.5f, 0.35f, 0.7f, Palette.black, x + 0.5f, 1.1f, 0f)
                box(0.25f, 0.35f, 0.25f, Palette.black, x + 0.75f, 1.05f, 0f)
                x -= carLen + gap
                for (i in 0 until carriages) {
                    val color = if (i % 2 == 0) Palette.trainCar else Palette.trainBody
                    box(carLen, 0.8f, 0.8f, color, x, 0.52f, 0f)
                    // window strip
                    box(carLen - 0.4f, 0.22f, 0.84f, Palette.window, x, 0.72f, 0f)
                    x -= carLen + gap
                }
            }
        }
        return Model(node, total / 2)
    }

    // MARK: - Rail signal

    /** Returns node; the two lights are named "lightA"/"lightB". */
    fun railSignal(): Node {
        val root = model {
            box(0.1f, 1.1f, 0.1f, Palette.black, 0f, 0.55f, 0f)
            box(0.52f, 0.3f, 0.12f, Palette.black, 0f, 1.18f, 0f)
        }
        for ((name, dx) in listOf("lightA" to -0.14f, "lightB" to 0.14f)) {
            val n = box(0.2f, 0.2f, 0.2f, Rgb(0.4f, 0.05f, 0.05f), dx, 1.18f, 0.08f)
            n.name = name
            root.addChild(n)
        }
        return root
    }

    // MARK: - Creatine

    fun creatineBottle(): Node {
        val root = model {
            box(0.34f, 0.40f, 0.28f, Palette.white, 0f, 0.22f, 0f)
            box(0.28f, 0.09f, 0.25f, Palette.whiteShade, 0f, 0.465f, 0f)
            box(0.30f, 0.10f, 0.27f, Palette.black, 0f, 0.56f, 0f)
            box(0.30f, 0.20f, 0.025f, Palette.cableRed, 0f, 0.24f, 0.153f)
            box(0.13f, 0.025f, 0.015f, Palette.white, -0.015f, 0.30f, 0.173f)
            box(0.13f, 0.025f, 0.015f, Palette.white, -0.015f, 0.18f, 0.173f)
            box(0.025f, 0.14f, 0.015f, Palette.white, -0.068f, 0.24f, 0.173f)
        }
        root.name = "creatineBottle"
        // glowing pickup pad so collectibles read from across the screen
        val pad = box(0.62f, 0.03f, 0.62f, Palette.accentGold, 0f, -0.165f, 0f)
        pad.emissive = floatArrayOf(0.35f, 0.28f, 0.05f)
        pad.opacity = 0.55f
        pad.runAction(
            RepeatForever(
                Sequence(
                    Group(ScaleTo(1.25f, 0.7f), FadeTo(0.15f, 0.7f)),
                    Group(ScaleTo(1.0f, 0.7f), FadeTo(0.55f, 0.7f)),
                )
            )
        )
        root.addChild(pad)
        root.position.y = 0.18f
        root.runAction(RepeatForever(RotateBy(PI.toFloat() * 2, 1.8f)))
        root.runAction(
            RepeatForever(
                Sequence(
                    MoveBy(0f, 0.12f, 0f, 0.6f).also { it.timing = Timing.EASE_IN_OUT },
                    MoveBy(0f, -0.12f, 0f, 0.6f).also { it.timing = Timing.EASE_IN_OUT },
                )
            )
        )
        return root
    }

    // MARK: - Ground decoration (merged into the row mesh)

    fun flowerInto(mb: MeshBuilder, color: Rgb) = with(mb) {
        box(0.05f, 0.22f, 0.05f, Palette.leafDark, 0f, 0.11f, 0f)
        box(0.16f, 0.07f, 0.16f, color, 0f, 0.25f, 0f)
        box(0.07f, 0.075f, 0.07f, Palette.accentGold, 0f, 0.26f, 0f)
    }

    fun grassTuftInto(mb: MeshBuilder) = with(mb) {
        box(0.06f, 0.16f, 0.06f, Palette.grassTuft, -0.07f, 0.08f, 0.03f)
        box(0.06f, 0.22f, 0.06f, Palette.grassTuft, 0.06f, 0.11f, -0.05f)
        box(0.06f, 0.13f, 0.06f, Palette.grassTuft, 0f, 0.065f, 0.07f)
    }

    // MARK: - Eagle

    fun eagle(): Node {
        val root = model {
            // body
            box(0.5f, 0.42f, 1.1f, Palette.eagleBrown, 0f, 0f, 0f)
            // head
            box(0.4f, 0.36f, 0.4f, Palette.white, 0f, 0.12f, 0.62f)
            // beak
            box(0.14f, 0.12f, 0.2f, Palette.beakOrange, 0f, 0.1f, 0.88f)
            // tail
            box(0.44f, 0.1f, 0.42f, Palette.white, 0f, 0.05f, -0.66f)
        }
        // wings (animated): pivot node at the wing root, blade offset outward
        for ((sx, name) in listOf(1f to "wingL", -1f to "wingR")) {
            val pivot = Node()
            pivot.name = name
            pivot.position.set(sx * 0.25f, 0.1f, -0.05f)
            pivot.addChild(box(1.05f, 0.08f, 0.55f, Palette.eagleBrown, sx * 0.5f, 0f, 0f))
            val flap = Sequence(
                RotateTo(0f, 0f, sx * 0.55f, 0.18f),
                RotateTo(0f, 0f, -sx * 0.35f, 0.18f),
            )
            pivot.runAction(RepeatForever(flap))
            root.addChild(pivot)
        }
        return root
    }
}
