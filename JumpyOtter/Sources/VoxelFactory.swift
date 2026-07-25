import SceneKit
import UIKit

/// Builds all voxel-style models programmatically from SCNBox primitives.
enum VoxelFactory {

    // MARK: - Helpers

    static func box(w: CGFloat, h: CGFloat, l: CGFloat, color: UIColor,
                    x: Float = 0, y: Float = 0, z: Float = 0, chamfer: CGFloat = 0.02) -> SCNNode {
        let geo = SCNBox(width: w, height: h, length: l, chamferRadius: chamfer)
        let mat = SCNMaterial()
        mat.diffuse.contents = color
        mat.lightingModel = .lambert
        geo.materials = [mat]
        let node = SCNNode(geometry: geo)
        node.position = SCNVector3(x, y, z)
        return node
    }

    // MARK: - Wiskers (player), built facing +Z

    static func wiskers() -> SCNNode {
        let root = SCNNode()
        root.name = "wiskers"
        // long tapered tail
        root.addChildNode(box(w: 0.28, h: 0.24, l: 0.42, color: Palette.otterDark, x: -0.04, y: 0.25, z: -0.37, chamfer: 0.06))
        let tailMiddle = box(w: 0.23, h: 0.19, l: 0.38, color: Palette.otterDark, x: 0.05, y: 0.18, z: -0.69, chamfer: 0.05)
        tailMiddle.eulerAngles.y = -0.28
        root.addChildNode(tailMiddle)
        let tailTip = box(w: 0.16, h: 0.14, l: 0.30, color: Palette.otter, x: 0.16, y: 0.13, z: -0.96, chamfer: 0.05)
        tailTip.eulerAngles.y = -0.38
        root.addChildNode(tailTip)
        // body and cream belly
        root.addChildNode(box(w: 0.50, h: 0.52, l: 0.48, color: Palette.otterDark, y: 0.34, chamfer: 0.08))
        root.addChildNode(box(w: 0.34, h: 0.34, l: 0.07, color: Palette.otterCream, y: 0.38, z: 0.275, chamfer: 0.05))
        // arms
        root.addChildNode(box(w: 0.11, h: 0.34, l: 0.22, color: Palette.otter, x: 0.29, y: 0.39, z: 0.03, chamfer: 0.04))
        root.addChildNode(box(w: 0.11, h: 0.34, l: 0.22, color: Palette.otter, x: -0.29, y: 0.39, z: 0.03, chamfer: 0.04))
        // feet
        root.addChildNode(box(w: 0.22, h: 0.15, l: 0.30, color: Palette.otter, x: 0.15, y: 0.075, z: 0.10, chamfer: 0.06))
        root.addChildNode(box(w: 0.22, h: 0.15, l: 0.30, color: Palette.otter, x: -0.15, y: 0.075, z: 0.10, chamfer: 0.06))
        // head and ears
        root.addChildNode(box(w: 0.57, h: 0.43, l: 0.46, color: Palette.otter, y: 0.76, z: 0.05, chamfer: 0.09))
        root.addChildNode(box(w: 0.15, h: 0.17, l: 0.18, color: Palette.otterDark, x: 0.31, y: 0.86, z: 0.01, chamfer: 0.06))
        root.addChildNode(box(w: 0.15, h: 0.17, l: 0.18, color: Palette.otterDark, x: -0.31, y: 0.86, z: 0.01, chamfer: 0.06))
        root.addChildNode(box(w: 0.08, h: 0.09, l: 0.04, color: Palette.otter, x: 0.315, y: 0.86, z: 0.115, chamfer: 0.03))
        root.addChildNode(box(w: 0.08, h: 0.09, l: 0.04, color: Palette.otter, x: -0.315, y: 0.86, z: 0.115, chamfer: 0.03))
        // eyes and highlights
        root.addChildNode(box(w: 0.075, h: 0.13, l: 0.055, color: Palette.black, x: 0.16, y: 0.82, z: 0.295, chamfer: 0.025))
        root.addChildNode(box(w: 0.075, h: 0.13, l: 0.055, color: Palette.black, x: -0.16, y: 0.82, z: 0.295, chamfer: 0.025))
        root.addChildNode(box(w: 0.025, h: 0.035, l: 0.02, color: Palette.white, x: 0.148, y: 0.85, z: 0.334, chamfer: 0.01))
        root.addChildNode(box(w: 0.025, h: 0.035, l: 0.02, color: Palette.white, x: -0.172, y: 0.85, z: 0.334, chamfer: 0.01))
        // white cheek muzzle and black nose
        root.addChildNode(box(w: 0.24, h: 0.17, l: 0.07, color: Palette.otterCream, x: 0.105, y: 0.68, z: 0.315, chamfer: 0.06))
        root.addChildNode(box(w: 0.24, h: 0.17, l: 0.07, color: Palette.otterCream, x: -0.105, y: 0.68, z: 0.315, chamfer: 0.06))
        root.addChildNode(box(w: 0.15, h: 0.105, l: 0.09, color: Palette.black, y: 0.735, z: 0.375, chamfer: 0.04))
        root.addChildNode(box(w: 0.035, h: 0.08, l: 0.035, color: Palette.black, y: 0.65, z: 0.37, chamfer: 0.01))
        // whiskers
        for side in [Float(-1), 1] {
            for (offset, angle) in [(Float(0.03), Float(0.36)), (Float(-0.035), Float(-0.36))] {
                let whisker = box(w: 0.18, h: 0.024, l: 0.025, color: Palette.black,
                                  x: side * 0.25, y: 0.66 + offset, z: 0.37, chamfer: 0.008)
                whisker.eulerAngles.z = side * angle
                root.addChildNode(whisker)
            }
        }
        let flat = root.flattenedClone()
        flat.name = "wiskers"
        flat.castsShadow = true
        return flat
    }

    // MARK: - Trees

    static func tree(height: Int) -> SCNNode {
        let root = SCNNode()
        let trunkH = CGFloat(0.35)
        root.addChildNode(box(w: 0.26, h: trunkH, l: 0.26, color: Palette.trunk, y: Float(trunkH / 2)))
        var y = Float(trunkH)
        let layers = max(1, height)
        for i in 0..<layers {
            let size = CGFloat(0.95) - CGFloat(i) * 0.18
            let h = CGFloat(0.34)
            let color = i % 2 == 0 ? Palette.leaf : Palette.leafDark
            root.addChildNode(box(w: size, h: h, l: size, color: color, y: y + Float(h / 2)))
            y += Float(h)
        }
        let flat = root.flattenedClone()
        flat.castsShadow = true
        return flat
    }

    static func paintedLady(color: UIColor) -> SCNNode {
        let root = SCNNode()
        root.addChildNode(box(w: 0.92, h: 0.16, l: 0.86, color: Palette.sidewalk, y: 0.08, chamfer: 0.02))
        root.addChildNode(box(w: 0.82, h: 1.30, l: 0.72, color: color, y: 0.80, chamfer: 0.025))
        root.addChildNode(box(w: 0.88, h: 0.09, l: 0.78, color: Palette.houseTrim, y: 1.43, chamfer: 0.015))
        root.addChildNode(box(w: 0.64, h: 0.18, l: 0.68, color: color, y: 1.56, chamfer: 0.02))
        root.addChildNode(box(w: 0.46, h: 0.16, l: 0.58, color: color, y: 1.72, chamfer: 0.02))
        root.addChildNode(box(w: 0.26, h: 0.14, l: 0.48, color: color, y: 1.87, chamfer: 0.02))
        for x in [Float(-0.34), 0.34] {
            root.addChildNode(box(w: 0.055, h: 1.22, l: 0.05, color: Palette.houseTrim, x: x, y: 0.82, z: -0.385, chamfer: 0.01))
        }
        root.addChildNode(box(w: 0.40, h: 0.62, l: 0.14, color: Palette.houseTrim, x: -0.11, y: 0.91, z: -0.41, chamfer: 0.025))
        for y in [Float(0.72), 1.02] {
            for x in [Float(-0.22), 0] {
                root.addChildNode(box(w: 0.13, h: 0.20, l: 0.035, color: Palette.window, x: x, y: y, z: -0.50, chamfer: 0.01))
            }
        }
        root.addChildNode(box(w: 0.19, h: 0.38, l: 0.055, color: Palette.cableRed, x: 0.22, y: 0.37, z: -0.40, chamfer: 0.015))
        root.addChildNode(box(w: 0.16, h: 0.21, l: 0.035, color: Palette.window, x: -0.18, y: 1.30, z: -0.385, chamfer: 0.01))
        root.addChildNode(box(w: 0.16, h: 0.21, l: 0.035, color: Palette.window, x: 0.16, y: 1.30, z: -0.385, chamfer: 0.01))
        root.addChildNode(box(w: 0.28, h: 0.08, l: 0.24, color: Palette.houseTrim, x: 0.22, y: 0.18, z: -0.46, chamfer: 0.01))
        let flat = root.flattenedClone()
        flat.castsShadow = true
        return flat
    }

    // MARK: - Vehicles (length axis = X, facing +X)

    /// Returns (node, halfLength)
    static func car(color: UIColor) -> (SCNNode, Float) {
        let root = SCNNode()
        root.addChildNode(box(w: 1.35, h: 0.32, l: 0.72, color: color, y: 0.32))
        // cabin with window band
        root.addChildNode(box(w: 0.72, h: 0.28, l: 0.64, color: Palette.window, x: -0.05, y: 0.62))
        root.addChildNode(box(w: 0.30, h: 0.30, l: 0.66, color: color, x: -0.38, y: 0.63))
        // headlights
        root.addChildNode(box(w: 0.06, h: 0.10, l: 0.14, color: UIColor(white: 1, alpha: 1), x: 0.68, y: 0.36, z: 0.22))
        root.addChildNode(box(w: 0.06, h: 0.10, l: 0.14, color: UIColor(white: 1, alpha: 1), x: 0.68, y: 0.36, z: -0.22))
        // wheels
        for wx in [Float(0.42), -0.42] {
            for wz in [Float(0.34), -0.34] {
                root.addChildNode(box(w: 0.26, h: 0.26, l: 0.14, color: Palette.wheel, x: wx, y: 0.13, z: wz))
            }
        }
        let flat = root.flattenedClone()
        flat.castsShadow = true
        return (flat, 0.72)
    }

    static func truck() -> (SCNNode, Float) {
        let root = SCNNode()
        let cabColor = Palette.carColors.randomElement()!
        // cab
        root.addChildNode(box(w: 0.62, h: 0.62, l: 0.78, color: cabColor, x: 0.88, y: 0.46))
        root.addChildNode(box(w: 0.30, h: 0.24, l: 0.70, color: Palette.window, x: 1.0, y: 0.72))
        // trailer
        root.addChildNode(box(w: 1.66, h: 0.78, l: 0.82, color: UIColor(white: 0.92, alpha: 1), x: -0.35, y: 0.58))
        // wheels
        for wx in [Float(1.0), 0.2, -0.9] {
            for wz in [Float(0.36), -0.36] {
                root.addChildNode(box(w: 0.28, h: 0.28, l: 0.14, color: Palette.wheel, x: wx, y: 0.14, z: wz))
            }
        }
        let flat = root.flattenedClone()
        flat.castsShadow = true
        return (flat, 1.25)
    }

    static func cableCar() -> (SCNNode, Float) {
        let root = SCNNode()
        root.addChildNode(box(w: 1.55, h: 0.22, l: 0.72, color: Palette.cableRed, y: 0.27, chamfer: 0.035))
        root.addChildNode(box(w: 1.34, h: 0.48, l: 0.64, color: Palette.cableCream, y: 0.60, chamfer: 0.025))
        root.addChildNode(box(w: 1.38, h: 0.23, l: 0.67, color: Palette.black, y: 0.68, chamfer: 0.015))
        for x in stride(from: Float(-0.55), through: Float(0.55), by: 0.28) {
            root.addChildNode(box(w: 0.045, h: 0.28, l: 0.70, color: Palette.cableRed, x: x, y: 0.68, chamfer: 0.008))
        }
        root.addChildNode(box(w: 1.48, h: 0.12, l: 0.78, color: Palette.cableCream, y: 0.93, chamfer: 0.04))
        root.addChildNode(box(w: 0.68, h: 0.16, l: 0.06, color: Palette.cableRed, y: 0.98, z: -0.43, chamfer: 0.015))
        root.addChildNode(box(w: 0.10, h: 0.60, l: 0.10, color: Palette.black, y: 1.22, chamfer: 0.01))
        root.addChildNode(box(w: 0.52, h: 0.06, l: 0.06, color: Palette.black, y: 1.51, chamfer: 0.01))
        for wx in [Float(0.53), -0.53] {
            for wz in [Float(0.34), -0.34] {
                root.addChildNode(box(w: 0.24, h: 0.24, l: 0.13, color: Palette.wheel, x: wx, y: 0.13, z: wz, chamfer: 0.04))
            }
        }
        let flat = root.flattenedClone()
        flat.castsShadow = true
        return (flat, 0.82)
    }

    // MARK: - Logs

    static func log(tiles: Int) -> (SCNNode, Float) {
        let len = CGFloat(tiles) * 0.95
        let root = SCNNode()
        root.addChildNode(box(w: len, h: 0.24, l: 0.72, color: Palette.logBrown, y: 0, chamfer: 0.06))
        // end caps
        root.addChildNode(box(w: 0.06, h: 0.18, l: 0.62, color: Palette.logEnd, x: Float(len / 2) - 0.02, y: 0))
        root.addChildNode(box(w: 0.06, h: 0.18, l: 0.62, color: Palette.logEnd, x: -Float(len / 2) + 0.02, y: 0))
        let flat = root.flattenedClone()
        flat.castsShadow = true
        return (flat, Float(len) / 2)
    }

    static func ferry(tiles: Int) -> (SCNNode, Float) {
        let len = CGFloat(tiles) * 0.95
        let root = SCNNode()
        root.addChildNode(box(w: len, h: 0.18, l: 0.72, color: Palette.houseTrim, y: 0.02, chamfer: 0.06))
        root.addChildNode(box(w: len - 0.12, h: 0.055, l: 0.75, color: Palette.cableRed, y: 0.015, chamfer: 0.02))
        root.addChildNode(box(w: len - 0.30, h: 0.055, l: 0.58, color: Palette.sidewalk, y: 0.09, chamfer: 0.015))
        let cabinX = Float(len / 2) - 0.34
        root.addChildNode(box(w: 0.38, h: 0.24, l: 0.48, color: Palette.houseTrim, x: cabinX, y: 0.20, chamfer: 0.025))
        root.addChildNode(box(w: 0.26, h: 0.11, l: 0.51, color: Palette.window, x: cabinX, y: 0.23, chamfer: 0.01))
        root.addChildNode(box(w: 0.46, h: 0.06, l: 0.56, color: Palette.cableRed, x: cabinX, y: 0.35, chamfer: 0.02))
        let flat = root.flattenedClone()
        flat.castsShadow = true
        return (flat, Float(len) / 2)
    }

    // MARK: - Train

    static func train(carriages: Int) -> (SCNNode, Float) {
        let root = SCNNode()
        let carLen: Float = 1.95
        let gap: Float = 0.12
        var x: Float = 0
        // engine
        let engine = SCNNode()
        engine.addChildNode(box(w: CGFloat(carLen), h: 0.85, l: 0.84, color: Palette.trainBody, y: 0.55))
        engine.addChildNode(box(w: 0.5, h: 0.35, l: 0.7, color: Palette.black, x: 0.5, y: 1.1))
        engine.addChildNode(box(w: 0.25, h: 0.35, l: 0.25, color: Palette.black, x: 0.75, y: 1.05))
        engine.position.x = x
        root.addChildNode(engine)
        x -= carLen + gap
        for i in 0..<carriages {
            let car = SCNNode()
            let color = i % 2 == 0 ? Palette.trainCar : Palette.trainBody
            car.addChildNode(box(w: CGFloat(carLen), h: 0.8, l: 0.8, color: color, y: 0.52))
            // window strip
            car.addChildNode(box(w: CGFloat(carLen) - 0.4, h: 0.22, l: 0.84, color: Palette.window, y: 0.72))
            car.position.x = x
            root.addChildNode(car)
            x -= carLen + gap
        }
        let total = carLen * Float(carriages + 1) + gap * Float(carriages)
        // center it
        let flatSource = SCNNode()
        root.position.x = total / 2 - carLen / 2
        flatSource.addChildNode(root)
        let flat = flatSource.flattenedClone()
        flat.castsShadow = true
        return (flat, total / 2)
    }

    // MARK: - Rail signal

    /// Returns node; the two light spheres are named "lightA"/"lightB".
    static func railSignal() -> SCNNode {
        let root = SCNNode()
        root.addChildNode(box(w: 0.1, h: 1.1, l: 0.1, color: Palette.black, y: 0.55))
        root.addChildNode(box(w: 0.52, h: 0.3, l: 0.12, color: Palette.black, y: 1.18))
        for (name, dx) in [("lightA", Float(-0.14)), ("lightB", Float(0.14))] {
            let geo = SCNSphere(radius: 0.085)
            let mat = SCNMaterial()
            mat.diffuse.contents = UIColor(red: 0.4, green: 0.05, blue: 0.05, alpha: 1)
            mat.emission.contents = UIColor.black
            geo.materials = [mat]
            let n = SCNNode(geometry: geo)
            n.name = name
            n.position = SCNVector3(dx, 1.18, 0.08)
            root.addChildNode(n)
        }
        return root
    }

    // MARK: - Creatine

    static func creatineBottle() -> SCNNode {
        let root = SCNNode()
        root.name = "creatineBottle"
        root.addChildNode(box(w: 0.34, h: 0.40, l: 0.28, color: Palette.white, y: 0.22, chamfer: 0.05))
        root.addChildNode(box(w: 0.28, h: 0.09, l: 0.25, color: Palette.whiteShade, y: 0.465, chamfer: 0.035))
        root.addChildNode(box(w: 0.30, h: 0.10, l: 0.27, color: Palette.black, y: 0.56, chamfer: 0.025))
        root.addChildNode(box(w: 0.30, h: 0.20, l: 0.025, color: Palette.cableRed, y: 0.24, z: 0.153, chamfer: 0.01))
        root.addChildNode(box(w: 0.13, h: 0.025, l: 0.015, color: Palette.white, x: -0.015, y: 0.30, z: 0.173, chamfer: 0.005))
        root.addChildNode(box(w: 0.13, h: 0.025, l: 0.015, color: Palette.white, x: -0.015, y: 0.18, z: 0.173, chamfer: 0.005))
        root.addChildNode(box(w: 0.025, h: 0.14, l: 0.015, color: Palette.white, x: -0.068, y: 0.24, z: 0.173, chamfer: 0.005))
        root.position.y = 0.18
        root.runAction(.repeatForever(.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 1.8)))
        return root
    }

    // MARK: - Eagle

    static func eagle() -> SCNNode {
        let root = SCNNode()
        // body
        root.addChildNode(box(w: 0.5, h: 0.42, l: 1.1, color: Palette.eagleBrown, y: 0))
        // head
        root.addChildNode(box(w: 0.4, h: 0.36, l: 0.4, color: Palette.white, y: 0.12, z: 0.62))
        // beak
        root.addChildNode(box(w: 0.14, h: 0.12, l: 0.2, color: Palette.beakOrange, y: 0.1, z: 0.88))
        // tail
        root.addChildNode(box(w: 0.44, h: 0.1, l: 0.42, color: Palette.white, y: 0.05, z: -0.66))
        // wings (animated)
        for (sx, name) in [(Float(1), "wingL"), (Float(-1), "wingR")] {
            let wing = box(w: 1.05, h: 0.08, l: 0.55, color: Palette.eagleBrown, x: sx * 0.75, y: 0.1, z: -0.05)
            wing.name = name
            wing.pivot = SCNMatrix4MakeTranslation(-sx * 0.5, 0, 0)
            let flap = SCNAction.sequence([
                .rotateTo(x: 0, y: 0, z: CGFloat(sx) * 0.55, duration: 0.18),
                .rotateTo(x: 0, y: 0, z: CGFloat(-sx) * 0.35, duration: 0.18),
            ])
            wing.runAction(.repeatForever(flap))
            root.addChildNode(wing)
        }
        root.castsShadow = true
        return root
    }
}
