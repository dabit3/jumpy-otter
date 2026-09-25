package com.devin.jumpyotter

import com.devin.jumpyotter.engine.FadeTo
import com.devin.jumpyotter.engine.MeshBuilder
import com.devin.jumpyotter.engine.MoveBy
import com.devin.jumpyotter.engine.Node
import com.devin.jumpyotter.engine.RepeatForever
import com.devin.jumpyotter.engine.Sequence
import kotlin.math.PI

enum class RowKind { GRASS, ROAD, RIVER, RAIL }

enum class TrainPhase { IDLE, WARNING, RUNNING }

class MovingObject(val node: Node, var x: Float, val halfLen: Float) {
    val presentationX: Float get() = node.position.x
}

class Row(val index: Int, val kind: RowKind) {
    val node = Node()

    var dir = 1f
    var speed = 0f
    val objects = ArrayList<MovingObject>()
    val blocked = HashSet<Int>()
    val creatine = HashMap<Int, Node>()

    // rail state
    var trainPhase = TrainPhase.IDLE
    var trainTimer = 0f
    var train: MovingObject? = null
    var signal: Node? = null
    var blinkTimer = 0f
    var blinkOn = false

    init {
        node.position.set(0f, 0f, index.toFloat())
    }

    /** Surface height the player stands on for this row. */
    val surfaceY: Float get() = if (kind == RowKind.RIVER) 0.11f else 0f
}

/** Generates rows procedurally and builds their scenery. Static scenery per row is merged into one mesh. */
class TerrainGenerator(private val parent: Node, private val onRowRemoved: (Row) -> Unit) {

    val rows = HashMap<Int, Row>()
    private var nextIndex = 0
    private var minIndex = 0  // lowest row index ever created

    // group state so we emit runs of the same kind (multi-lane roads etc.)
    private var pendingKind = RowKind.GRASS
    private var pendingCount = 0
    private var lastGroupKind = RowKind.GRASS
    private var lastRiverDir = 1f

    fun reset() {
        for (row in rows.values) {
            row.node.removeFromParent()
            onRowRemoved(row)
        }
        rows.clear()
        nextIndex = 0
        minIndex = 0
        pendingKind = RowKind.GRASS
        pendingCount = 0
        lastGroupKind = RowKind.GRASS
    }

    /** Ensure rows exist for indices `from..to`; cull rows below `from`. */
    fun ensure(from: Int, to: Int) {
        val it = rows.entries.iterator()
        while (it.hasNext()) {
            val (idx, row) = it.next()
            if (idx < from) {
                row.node.removeFromParent()
                onRowRemoved(row)
                it.remove()
            }
        }
        // backfill grass forest behind the start (runs once; culled rows are never re-created
        // because minIndex tracks the lowest index ever built)
        while (minIndex > from) {
            minIndex -= 1
            val row = buildRow(minIndex, RowKind.GRASS)
            rows[minIndex] = row
            parent.addChild(row.node)
        }
        while (nextIndex <= to) {
            val row = makeRow(nextIndex)
            rows[nextIndex] = row
            parent.addChild(row.node)
            nextIndex += 1
        }
    }

    // MARK: - Row creation

    private fun makeRow(index: Int): Row {
        if (index <= 0) return buildRow(index, RowKind.GRASS)
        if (pendingCount == 0) rollNextGroup(index)
        pendingCount -= 1
        return buildRow(index, pendingKind)
    }

    private fun rollNextGroup(index: Int) {
        if (lastGroupKind != RowKind.GRASS) {
            pendingKind = RowKind.GRASS
            pendingCount = 1
            lastGroupKind = RowKind.GRASS
            return
        }
        // Difficulty: hazards become more frequent with distance.
        val difficulty = minOf(index / 150f, 1f)
        for (attempt in 0 until 8) {
            val r = rand01()
            val grassChance = 0.34f - 0.12f * difficulty
            val roadChance = 0.30f + 0.06f * difficulty
            val riverChance = 0.22f + 0.04f * difficulty
            if (r < grassChance) {
                pendingKind = RowKind.GRASS
                pendingCount = randInt(1, 2)
            } else if (r < grassChance + roadChance) {
                pendingKind = RowKind.ROAD
                pendingCount = randInt(1, if (index > 12) 3 else 2)
            } else if (r < grassChance + roadChance + riverChance) {
                pendingKind = RowKind.RIVER
                pendingCount = randInt(1, if (index > 20) 3 else 2)
                lastRiverDir = if (randBool()) 1f else -1f
            } else {
                pendingKind = RowKind.RAIL
                pendingCount = 1
            }
            // avoid back-to-back hazard groups of the same kind (mega-roads etc.)
            if (pendingKind == RowKind.GRASS || pendingKind != lastGroupKind) break
        }
        lastGroupKind = pendingKind
    }

    private fun buildRow(index: Int, kind: RowKind): Row {
        val row = Row(index, kind)
        val mb = MeshBuilder()
        when (kind) {
            RowKind.GRASS -> buildGrass(row, mb)
            RowKind.ROAD -> buildRoad(row, mb)
            RowKind.RIVER -> buildRiver(row, mb)
            RowKind.RAIL -> buildRail(row, mb)
        }
        if (!mb.isEmpty) row.node.addChild(Node(mb.build()))
        return row
    }

    // MARK: - Grass

    private fun buildGrass(row: Row, mb: MeshBuilder) {
        val light = row.index % 2 == 0
        mb.box(K.visualHalfWidth * 2, 0.5f, 1.0f, if (light) Palette.grassLight else Palette.grassDark, 0f, -0.25f, 0f)
        // darker side strips outside the playable area
        for (sx in floatArrayOf(1f, -1f)) {
            val stripW = K.visualHalfWidth - K.maxCol - 0.5f
            mb.box(stripW, 0.04f, 1.0f, Palette.sidewalk, sx * (K.maxCol + 0.5f + stripW / 2), 0.02f, 0f)
            mb.box(0.12f, 0.10f, 1.0f, Palette.curb, sx * (K.maxCol + 0.56f), 0.05f, 0f)
        }

        // colorful homes and trees outside the playable strip
        for (col in (-K.visualHalfWidth.toInt() + 1)..(K.visualHalfWidth.toInt() - 1)) {
            if (col >= K.minCol - 1 && col <= K.maxCol + 1) continue
            val roll = rand01()
            if (roll < 0.52f) {
                val scale = rand(0.82f, 1.08f)
                mb.withOffset(col.toFloat(), 0f, 0f, scale) {
                    VoxelFactory.paintedLadyInto(this, Palette.houseColors.random())
                }
            } else if (roll < 0.70f) {
                mb.withOffset(col.toFloat(), 0f, 0f) { VoxelFactory.treeInto(this, randInt(2, 3)) }
            }
        }

        // wildflowers and grass tufts inside the playable strip
        for (col in K.minCol..K.maxCol) {
            if (rand01() >= 0.28f) continue
            val ox = col + rand(-0.32f, 0.32f)
            val oz = rand(-0.32f, 0.32f)
            mb.withOffset(ox, 0f, oz, 1f, rand(0f, PI.toFloat())) {
                if (rand01() < 0.55f) VoxelFactory.flowerInto(this, Palette.flowerColors.random())
                else VoxelFactory.grassTuftInto(this)
            }
        }

        // trees inside the playable strip
        if (row.index == 0) return  // keep spawn row clear
        var cols = (K.minCol..K.maxCol).shuffled()
        val treeCount = if (row.index < 0) randInt(2, 4) else randInt(0, 3)
        var placed = 0
        for (col in cols) {
            if (placed >= treeCount) break
            // always keep column 0 clear on the first few rows so the player has a path
            if (row.index > 0 && row.index <= 3 && col == 0) continue
            if (row.blocked.size >= 6) break  // never wall off the row
            mb.withOffset(col.toFloat(), 0f, 0f) { VoxelFactory.treeInto(this, randInt(1, 3)) }
            row.blocked.add(col)
            placed += 1
        }
        // creatine chance
        if (row.index > 0 && rand01() < 0.12f) {
            cols = (K.minCol..K.maxCol).filter { !row.blocked.contains(it) }.shuffled()
            cols.firstOrNull()?.let { col ->
                val c = VoxelFactory.creatineBottle()
                c.position.x = col.toFloat()
                row.node.addChild(c)
                row.creatine[col] = c
            }
        }
    }

    // MARK: - Road

    private fun buildRoad(row: Row, mb: MeshBuilder) {
        mb.box(K.visualHalfWidth * 2, 0.5f, 1.0f, Palette.road, 0f, -0.25f, 0f)
        for (z in floatArrayOf(-0.18f, 0.18f)) {
            mb.box(K.visualHalfWidth * 2, 0.025f, 0.035f, Palette.railSteel, 0f, 0.013f, z)
        }

        // lane divider dashes if the previous row was also road
        if (rows[row.index - 1]?.kind == RowKind.ROAD) {
            var x = -K.visualHalfWidth + 0.5f
            while (x < K.visualHalfWidth) {
                mb.box(0.45f, 0.02f, 0.08f, Rgb.gray(0.95f), x, 0.011f, -0.5f)
                x += 1.4f
            }
        }

        val difficulty = minOf(maxOf(row.index, 0) / 120f, 1f)
        row.dir = if (randBool()) 1f else -1f
        row.speed = rand(1.8f, 3.4f) + difficulty * 1.6f

        // spawn traffic spread around the wrap track
        var x = -K.wrapHalf + rand(0f, 2f)
        while (x < K.wrapHalf - 2) {
            val vehicleRoll = rand01()
            val vehicle = when {
                vehicleRoll < 0.20f -> VoxelFactory.cableCar()
                vehicleRoll < 0.36f -> VoxelFactory.truck()
                else -> VoxelFactory.car(Palette.carColors.random())
            }
            if (row.dir < 0) vehicle.node.eulerAngles.y = PI.toFloat()
            x += vehicle.halfLen
            vehicle.node.position.set(x, 0f, 0f)
            row.node.addChild(vehicle.node)
            row.objects.add(MovingObject(vehicle.node, x, vehicle.halfLen))
            x += vehicle.halfLen + rand(3.4f, 9.0f) - difficulty * 1.6f
        }

        // creatine chance on road
        if (row.index > 0 && rand01() < 0.08f) {
            val col = randInt(K.minCol, K.maxCol)
            val c = VoxelFactory.creatineBottle()
            c.position.x = col.toFloat()
            row.node.addChild(c)
            row.creatine[col] = c
        }
    }

    // MARK: - River

    private fun buildRiver(row: Row, mb: MeshBuilder) {
        // river bed and water surface
        mb.box(K.visualHalfWidth * 2, 0.3f, 1.0f, Palette.riverBed, 0f, -0.45f, 0f)
        mb.box(K.visualHalfWidth * 2, 0.16f, 1.0f, Palette.water, 0f, -0.18f, 0f)
        // foam streaks drifting with the current
        var fx = -K.visualHalfWidth + rand(0.2f, 1.4f)
        while (fx < K.visualHalfWidth - 0.6f) {
            val foam = VoxelFactory.box(rand(0.35f, 0.9f), 0.02f, 0.06f, Palette.waterFoam, fx, -0.095f, rand(-0.4f, 0.4f))
            foam.opacity = 0.75f
            val drift = rand(0.8f, 1.6f)
            foam.runAction(
                RepeatForever(
                    Sequence(
                        MoveBy(drift, 0f, 0f, rand(1.6f, 2.8f)),
                        FadeTo(0f, 0.3f),
                        MoveBy(-drift, 0f, 0f, 0f),
                        FadeTo(0.75f, 0.3f),
                    )
                )
            )
            row.node.addChild(foam)
            fx += rand(1.8f, 3.6f)
        }

        // alternate direction within river groups
        lastRiverDir = -lastRiverDir
        row.dir = lastRiverDir
        row.speed = rand(1.0f, 2.1f)

        var x = -K.wrapHalf + rand(0f, 1.5f)
        while (x < K.wrapHalf - 2) {
            val tiles = randInt(2, 4)
            val ferry = VoxelFactory.ferry(tiles)
            x += ferry.halfLen
            ferry.node.position.set(x, 0f, 0f)
            row.node.addChild(ferry.node)
            row.objects.add(MovingObject(ferry.node, x, ferry.halfLen))
            x += ferry.halfLen + rand(1.6f, 3.4f)
        }
    }

    // MARK: - Rail

    private fun buildRail(row: Row, mb: MeshBuilder) {
        mb.box(K.visualHalfWidth * 2, 0.5f, 1.0f, Palette.railBed, 0f, -0.25f, 0f)
        // ties
        var x = -K.visualHalfWidth + 0.3f
        while (x < K.visualHalfWidth) {
            mb.box(0.28f, 0.06f, 0.8f, Palette.railTie, x, 0.03f, 0f)
            x += 0.62f
        }
        // rails
        for (dz in floatArrayOf(0.22f, -0.22f)) {
            mb.box(K.visualHalfWidth * 2, 0.07f, 0.09f, Palette.railSteel, 0f, 0.085f, dz)
        }
        // signal at the side of the playable area
        val signal = VoxelFactory.railSignal()
        signal.position.set(K.maxCol + 1.4f, 0f, -0.2f)
        row.node.addChild(signal)
        row.signal = signal

        row.dir = if (randBool()) 1f else -1f
        row.trainPhase = TrainPhase.IDLE
        row.trainTimer = rand(1.5f, 5.0f)
    }
}
