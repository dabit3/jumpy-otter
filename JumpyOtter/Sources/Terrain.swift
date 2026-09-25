import SceneKit
import UIKit

enum RowKind {
    case grass, road, river, rail
}

enum TrainPhase {
    case idle, warning, running
}

final class MovingObject {
    let node: SCNNode
    var x: Float
    let halfLen: Float
    var presentationX: Float { node.presentation.position.x }
    init(node: SCNNode, x: Float, halfLen: Float) {
        self.node = node
        self.x = x
        self.halfLen = halfLen
    }
}

final class Row {
    let index: Int
    let kind: RowKind
    let node = SCNNode()

    var dir: Float = 1
    var speed: Float = 0
    var objects: [MovingObject] = []
    var blocked: Set<Int> = []
    var creatine: [Int: SCNNode] = [:]

    // rail state
    var trainPhase: TrainPhase = .idle
    var trainTimer: Float = 0
    var train: MovingObject?
    var signal: SCNNode?
    var blinkTimer: Float = 0
    var blinkOn = false

    init(index: Int, kind: RowKind) {
        self.index = index
        self.kind = kind
        node.position = SCNVector3(0, 0, Float(index))
    }

    /// Surface height the player stands on for this row.
    var surfaceY: Float { kind == .river ? 0.11 : 0 }
}

/// Generates rows procedurally and builds their scenery.
final class TerrainGenerator {

    private(set) var rows: [Int: Row] = [:]
    private let parent: SCNNode
    private var nextIndex = 0
    private var minIndex = 0  // lowest row index ever created

    // group state so we emit runs of the same kind (multi-lane roads etc.)
    private var pendingKind: RowKind = .grass
    private var pendingCount = 0
    private var lastGroupKind: RowKind = .grass
    private var lastRiverDir: Float = 1

    init(parent: SCNNode) {
        self.parent = parent
    }

    func reset() {
        for (_, row) in rows { row.node.removeFromParentNode() }
        rows.removeAll()
        nextIndex = 0
        minIndex = 0
        pendingKind = .grass
        pendingCount = 0
        lastGroupKind = .grass
    }

    /// Ensure rows exist for indices `from...to`; cull rows below `from`.
    func ensure(from: Int, to: Int) {
        for (idx, row) in rows where idx < from {
            row.node.removeFromParentNode()
            rows.removeValue(forKey: idx)
        }
        // backfill grass forest behind the start (runs once; culled rows are never re-created
        // because minIndex tracks the lowest index ever built)
        while minIndex > from {
            minIndex -= 1
            let row = buildRow(index: minIndex, kind: .grass)
            rows[minIndex] = row
            parent.addChildNode(row.node)
        }
        while nextIndex <= to {
            let row = makeRow(at: nextIndex)
            rows[nextIndex] = row
            parent.addChildNode(row.node)
            nextIndex += 1
        }
    }

    // MARK: - Row creation

    private func makeRow(at index: Int) -> Row {
        if index <= 0 { return buildRow(index: index, kind: .grass) }
        if pendingCount == 0 { rollNextGroup(at: index) }
        pendingCount -= 1
        return buildRow(index: index, kind: pendingKind)
    }

    private func rollNextGroup(at index: Int) {
        if lastGroupKind != .grass {
            pendingKind = .grass
            pendingCount = 1
            lastGroupKind = .grass
            return
        }
        // Difficulty: hazards become more frequent with distance.
        let difficulty = min(Float(index) / 150.0, 1.0)
        for _ in 0..<8 {
            let r = Float.random(in: 0..<1)
            let grassChance: Float = 0.34 - 0.12 * difficulty
            let roadChance: Float = 0.30 + 0.06 * difficulty
            let riverChance: Float = 0.22 + 0.04 * difficulty
            if r < grassChance {
                pendingKind = .grass
                pendingCount = Int.random(in: 1...2)
            } else if r < grassChance + roadChance {
                pendingKind = .road
                pendingCount = Int.random(in: 1...(index > 12 ? 3 : 2))
            } else if r < grassChance + roadChance + riverChance {
                pendingKind = .river
                pendingCount = Int.random(in: 1...(index > 20 ? 3 : 2))
                lastRiverDir = Bool.random() ? 1 : -1
            } else {
                pendingKind = .rail
                pendingCount = 1
            }
            // avoid back-to-back hazard groups of the same kind (mega-roads etc.)
            if pendingKind == .grass || pendingKind != lastGroupKind { break }
        }
        lastGroupKind = pendingKind
    }

    private func buildRow(index: Int, kind: RowKind) -> Row {
        let row = Row(index: index, kind: kind)
        switch kind {
        case .grass: buildGrass(row)
        case .road:  buildRoad(row)
        case .river: buildRiver(row)
        case .rail:  buildRail(row)
        }
        return row
    }

    // MARK: - Grass

    private func buildGrass(_ row: Row) {
        let light = row.index % 2 == 0
        let base = VoxelFactory.box(
            w: CGFloat(K.visualHalfWidth * 2), h: 0.5, l: 1.0,
            color: light ? Palette.grassLight : Palette.grassDark,
            y: -0.25, chamfer: 0)
        row.node.addChildNode(base)
        // darker side strips outside the playable area
        for sx in [Float(1), -1] {
            let stripW = K.visualHalfWidth - Float(K.maxCol) - 0.5
            let side = VoxelFactory.box(
                w: CGFloat(stripW), h: 0.04, l: 1.0,
                color: Palette.sidewalk,
                x: sx * (Float(K.maxCol) + 0.5 + stripW / 2),
                y: 0.02, chamfer: 0)
            side.castsShadow = false
            row.node.addChildNode(side)
            row.node.addChildNode(VoxelFactory.box(
                w: 0.12, h: 0.10, l: 1.0, color: Palette.curb,
                x: sx * (Float(K.maxCol) + 0.56), y: 0.05, chamfer: 0.01))
        }

        // colorful homes and trees outside the playable strip
        for col in stride(from: Int(-K.visualHalfWidth) + 1, through: Int(K.visualHalfWidth) - 1, by: 1) {
            if col >= K.minCol - 1 && col <= K.maxCol + 1 { continue }
            let roll = Float.random(in: 0..<1)
            if roll < 0.52 {
                let house = VoxelFactory.paintedLady(color: Palette.houseColors.randomElement()!)
                let scale = Float.rand(0.82...1.08)
                house.scale = SCNVector3(scale, scale, scale)
                house.position = SCNVector3(Float(col), 0, 0)
                row.node.addChildNode(house)
            } else if roll < 0.70 {
                let t = VoxelFactory.tree(height: Int.random(in: 2...3))
                t.position = SCNVector3(Float(col), 0, 0)
                row.node.addChildNode(t)
            }
        }

        // wildflowers and grass tufts inside the playable strip
        for col in K.minCol...K.maxCol where Float.random(in: 0..<1) < 0.28 {
            let ox = Float(col) + Float.rand(-0.32...0.32)
            let oz = Float.rand(-0.32...0.32)
            let deco: SCNNode
            if Float.random(in: 0..<1) < 0.55 {
                deco = VoxelFactory.flower(color: Palette.flowerColors.randomElement()!)
            } else {
                deco = VoxelFactory.grassTuft()
            }
            deco.position = SCNVector3(ox, 0, oz)
            deco.eulerAngles.y = Float.rand(0...Float.pi)
            row.node.addChildNode(deco)
        }

        // trees inside the playable strip
        guard row.index != 0 else { return }  // keep spawn row clear
        var cols = Array(K.minCol...K.maxCol).shuffled()
        let treeCount = row.index < 0 ? Int.random(in: 2...4) : Int.random(in: 0...3)
        var placed = 0
        for col in cols {
            if placed >= treeCount { break }
            // always keep column 0 clear on the first few rows so the player has a path
            if row.index > 0 && row.index <= 3 && col == 0 { continue }
            if row.blocked.count >= 6 { break }  // never wall off the row
            let t = VoxelFactory.tree(height: Int.random(in: 1...3))
            t.position = SCNVector3(Float(col), 0, 0)
            row.node.addChildNode(t)
            row.blocked.insert(col)
            placed += 1
        }
        // creatine chance
        if row.index > 0, Float.random(in: 0..<1) < 0.12 {
            cols = Array(K.minCol...K.maxCol).filter { !row.blocked.contains($0) }.shuffled()
            if let col = cols.first {
                let c = VoxelFactory.creatineBottle()
                c.position.x = Float(col)
                row.node.addChildNode(c)
                row.creatine[col] = c
            }
        }
    }

    // MARK: - Road

    private func buildRoad(_ row: Row) {
        let base = VoxelFactory.box(
            w: CGFloat(K.visualHalfWidth * 2), h: 0.5, l: 1.0,
            color: Palette.road, y: -0.25, chamfer: 0)
        row.node.addChildNode(base)
        for z in [Float(-0.18), 0.18] {
            row.node.addChildNode(VoxelFactory.box(
                w: CGFloat(K.visualHalfWidth * 2), h: 0.025, l: 0.035,
                color: Palette.railSteel, y: 0.013, z: z, chamfer: 0))
        }

        // lane divider dashes if the previous row was also road
        if rows[row.index - 1]?.kind == .road {
            var x: Float = -K.visualHalfWidth + 0.5
            while x < K.visualHalfWidth {
                let dash = VoxelFactory.box(w: 0.45, h: 0.02, l: 0.08,
                                            color: UIColor(white: 1, alpha: 0.85),
                                            x: x, y: 0.011, z: -0.5, chamfer: 0)
                row.node.addChildNode(dash)
                x += 1.4
            }
        }

        let difficulty = min(Float(max(row.index, 0)) / 120.0, 1.0)
        row.dir = Bool.random() ? 1 : -1
        row.speed = Float.rand(1.8...3.4) + difficulty * 1.6

        // spawn traffic spread around the wrap track
        var x: Float = -K.wrapHalf + Float.rand(0...2)
        while x < K.wrapHalf - 2 {
            let vehicleRoll = Float.random(in: 0..<1)
            let vehicle: (SCNNode, Float)
            if vehicleRoll < 0.20 {
                vehicle = VoxelFactory.cableCar()
            } else if vehicleRoll < 0.36 {
                vehicle = VoxelFactory.truck()
            } else {
                vehicle = VoxelFactory.car(color: Palette.carColors.randomElement()!)
            }
            let (node, halfLen) = vehicle
            if row.dir < 0 { node.eulerAngles.y = .pi }
            x += halfLen
            node.position = SCNVector3(x, 0, 0)
            row.node.addChildNode(node)
            row.objects.append(MovingObject(node: node, x: x, halfLen: halfLen))
            x += halfLen + Float.rand(3.4...9.0) - difficulty * 1.6
        }

        // creatine chance on road
        if row.index > 0, Float.random(in: 0..<1) < 0.08 {
            let col = Int.random(in: K.minCol...K.maxCol)
            let c = VoxelFactory.creatineBottle()
            c.position.x = Float(col)
            row.node.addChildNode(c)
            row.creatine[col] = c
        }
    }

    // MARK: - River

    private func buildRiver(_ row: Row) {
        // river bed
        let bed = VoxelFactory.box(
            w: CGFloat(K.visualHalfWidth * 2), h: 0.3, l: 1.0,
            color: Palette.riverBed, y: -0.45, chamfer: 0)
        row.node.addChildNode(bed)
        // water surface (slightly translucent)
        let water = VoxelFactory.box(
            w: CGFloat(K.visualHalfWidth * 2), h: 0.16, l: 1.0,
            color: Palette.water, y: -0.18, chamfer: 0)
        water.geometry?.firstMaterial?.transparency = 0.92
        water.castsShadow = false
        row.node.addChildNode(water)
        // foam streaks drifting with the current
        var fx: Float = -K.visualHalfWidth + Float.rand(0.2...1.4)
        while fx < K.visualHalfWidth - 0.6 {
            let len = CGFloat(Float.rand(0.35...0.9))
            let foam = VoxelFactory.box(w: len, h: 0.02, l: 0.06, color: Palette.waterFoam,
                                        x: fx, y: -0.095, z: Float.rand(-0.4...0.4), chamfer: 0)
            foam.castsShadow = false
            foam.opacity = 0.75
            let drift = CGFloat(Float.rand(0.8...1.6))
            foam.runAction(.repeatForever(.sequence([
                .moveBy(x: drift, y: 0, z: 0, duration: TimeInterval(Float.rand(1.6...2.8))),
                .fadeOut(duration: 0.3),
                .moveBy(x: -drift, y: 0, z: 0, duration: 0),
                .fadeOpacity(to: 0.75, duration: 0.3),
            ])))
            row.node.addChildNode(foam)
            fx += Float.rand(1.8...3.6)
        }

        // alternate direction within river groups
        lastRiverDir = -lastRiverDir
        row.dir = lastRiverDir
        row.speed = Float.rand(1.0...2.1)

        var x: Float = -K.wrapHalf + Float.rand(0...1.5)
        while x < K.wrapHalf - 2 {
            let tiles = Int.random(in: 2...4)
            let (node, halfLen) = VoxelFactory.ferry(tiles: tiles)
            x += halfLen
            node.position = SCNVector3(x, 0.0, 0)
            row.node.addChildNode(node)
            row.objects.append(MovingObject(node: node, x: x, halfLen: halfLen))
            x += halfLen + Float.rand(1.6...3.4)
        }
    }

    // MARK: - Rail

    private func buildRail(_ row: Row) {
        let base = VoxelFactory.box(
            w: CGFloat(K.visualHalfWidth * 2), h: 0.5, l: 1.0,
            color: Palette.railBed, y: -0.25, chamfer: 0)
        row.node.addChildNode(base)
        // ties
        var x: Float = -K.visualHalfWidth + 0.3
        while x < K.visualHalfWidth {
            row.node.addChildNode(VoxelFactory.box(w: 0.28, h: 0.06, l: 0.8,
                                                   color: Palette.railTie, x: x, y: 0.03, chamfer: 0))
            x += 0.62
        }
        // rails
        for dz in [Float(0.22), -0.22] {
            row.node.addChildNode(VoxelFactory.box(w: CGFloat(K.visualHalfWidth * 2), h: 0.07, l: 0.09,
                                                   color: Palette.railSteel, y: 0.085, z: dz, chamfer: 0))
        }
        // signal at the side of the playable area
        let signal = VoxelFactory.railSignal()
        signal.position = SCNVector3(Float(K.maxCol) + 1.4, 0, -0.2)
        row.node.addChildNode(signal)
        row.signal = signal

        row.dir = Bool.random() ? 1 : -1
        row.trainPhase = .idle
        row.trainTimer = Float.rand(1.5...5.0)
    }
}
