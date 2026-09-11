import UIKit
import SceneKit

enum K {
    // Playable lateral bounds (tile columns)
    static let minCol = -4
    static let maxCol = 4
    // Visual row width extends beyond playable area
    static let visualHalfWidth: Float = 16
    // Moving objects wrap within this half-length
    static let wrapHalf: Float = 13

    static let hopDuration: TimeInterval = 0.135
    static let hopHeight: CGFloat = 0.45

    static let rowsAhead = 22
    static let rowsBehindKeep = 16

    static let cameraAutoAdvance: Float = 0.35
    static let cameraBehindLimit: Float = 7.5
    static let idleEagleSeconds: Float = 6.0

    static let playerHalfWidth: Float = 0.30
    static let trainPlayerHalfWidth: Float = 0.12
    static let trainCollisionInset: Float = 0.22
    static let trainRowHalfDepth: Float = 0.30

    // multiplayer garbage: road traffic speed surge on rivals
    static let garbageSpeedBoost: Float = 1.7
    static let garbageBoostSeconds: Float = 4.0

    // arcade milestone banner cadence (rows)
    static let milestoneEvery = 25
}

/// Arcade rank awarded on the game-over card.
enum Rank {
    static func title(for score: Int) -> String {
        switch score {
        case ..<10: return "ROOKIE"
        case ..<25: return "HOPPER"
        case ..<50: return "PRO"
        case ..<100: return "LEGEND"
        default: return "OTTERLORD"
        }
    }

    static func color(for score: Int) -> UIColor {
        switch score {
        case ..<10: return Palette.hudSilver
        case ..<25: return Palette.leaf
        case ..<50: return Palette.window
        case ..<100: return Palette.accentGold
        default: return Palette.hotOrange
        }
    }
}

enum Palette {
    static let grassLight = UIColor(red: 0.52, green: 0.80, blue: 0.38, alpha: 1)
    static let grassDark  = UIColor(red: 0.45, green: 0.73, blue: 0.33, alpha: 1)
    static let grassSide  = UIColor(red: 0.30, green: 0.52, blue: 0.27, alpha: 1)
    static let grassTuft  = UIColor(red: 0.36, green: 0.66, blue: 0.28, alpha: 1)
    static let road       = UIColor(red: 0.22, green: 0.23, blue: 0.28, alpha: 1)
    static let roadSide   = UIColor(red: 0.25, green: 0.26, blue: 0.30, alpha: 1)
    static let water      = UIColor(red: 0.20, green: 0.62, blue: 0.86, alpha: 1)
    static let riverBed   = UIColor(red: 0.12, green: 0.38, blue: 0.58, alpha: 1)
    static let waterFoam  = UIColor(red: 0.80, green: 0.93, blue: 0.99, alpha: 1)
    static let flowerColors: [UIColor] = [
        UIColor(red: 0.98, green: 0.45, blue: 0.62, alpha: 1),
        UIColor(red: 1.00, green: 0.86, blue: 0.25, alpha: 1),
        UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1),
        UIColor(red: 0.60, green: 0.55, blue: 0.95, alpha: 1),
    ]
    // HUD / arcade chrome
    static let hudNavy    = UIColor(red: 0.07, green: 0.09, blue: 0.20, alpha: 1)
    static let hudInk     = UIColor(red: 0.10, green: 0.07, blue: 0.16, alpha: 1)
    static let hudCream   = UIColor(red: 1.00, green: 0.96, blue: 0.86, alpha: 1)
    static let hudSilver  = UIColor(red: 0.80, green: 0.84, blue: 0.90, alpha: 1)
    static let hotOrange  = UIColor(red: 1.00, green: 0.45, blue: 0.15, alpha: 1)
    static let dangerRed  = UIColor(red: 0.95, green: 0.20, blue: 0.22, alpha: 1)
    static let sidewalk   = UIColor(red: 0.72, green: 0.70, blue: 0.66, alpha: 1)
    static let curb       = UIColor(red: 0.88, green: 0.86, blue: 0.80, alpha: 1)
    static let railBed    = UIColor(red: 0.48, green: 0.46, blue: 0.42, alpha: 1)
    static let railTie    = UIColor(red: 0.35, green: 0.26, blue: 0.18, alpha: 1)
    static let railSteel  = UIColor(red: 0.65, green: 0.66, blue: 0.70, alpha: 1)
    static let trunk      = UIColor(red: 0.55, green: 0.38, blue: 0.22, alpha: 1)
    static let leaf       = UIColor(red: 0.30, green: 0.68, blue: 0.29, alpha: 1)
    static let leafDark   = UIColor(red: 0.24, green: 0.58, blue: 0.24, alpha: 1)
    static let logBrown   = UIColor(red: 0.62, green: 0.42, blue: 0.24, alpha: 1)
    static let logEnd     = UIColor(red: 0.78, green: 0.60, blue: 0.38, alpha: 1)
    static let white      = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1)
    static let whiteShade = UIColor(red: 0.88, green: 0.89, blue: 0.92, alpha: 1)
    static let otter      = UIColor(red: 1.00, green: 0.65, blue: 0.27, alpha: 1)
    static let otterDark  = UIColor(red: 0.90, green: 0.54, blue: 0.16, alpha: 1)
    static let otterCream = UIColor(red: 0.98, green: 0.97, blue: 0.93, alpha: 1)
    static let combRed    = UIColor(red: 0.89, green: 0.24, blue: 0.20, alpha: 1)
    static let beakOrange = UIColor(red: 0.95, green: 0.58, blue: 0.13, alpha: 1)
    static let black      = UIColor(red: 0.13, green: 0.13, blue: 0.16, alpha: 1)
    static let accentGold = UIColor(red: 1.00, green: 0.84, blue: 0.20, alpha: 1)
    static let sky        = UIColor(red: 0.53, green: 0.78, blue: 0.95, alpha: 1)
    static let wheel      = UIColor(red: 0.15, green: 0.15, blue: 0.18, alpha: 1)
    static let window     = UIColor(red: 0.55, green: 0.80, blue: 0.95, alpha: 1)
    static let cableRed   = UIColor(red: 0.72, green: 0.13, blue: 0.12, alpha: 1)
    static let cableCream = UIColor(red: 0.94, green: 0.86, blue: 0.68, alpha: 1)
    static let houseTrim  = UIColor(red: 0.96, green: 0.91, blue: 0.81, alpha: 1)
    static let houseColors: [UIColor] = [
        UIColor(red: 0.40, green: 0.60, blue: 0.68, alpha: 1),
        UIColor(red: 0.82, green: 0.45, blue: 0.37, alpha: 1),
        UIColor(red: 0.86, green: 0.65, blue: 0.27, alpha: 1),
        UIColor(red: 0.46, green: 0.64, blue: 0.50, alpha: 1),
        UIColor(red: 0.59, green: 0.51, blue: 0.68, alpha: 1),
    ]
    static let trainBody  = UIColor(red: 0.75, green: 0.22, blue: 0.20, alpha: 1)
    static let trainCar   = UIColor(red: 0.45, green: 0.48, blue: 0.55, alpha: 1)
    static let eagleBrown = UIColor(red: 0.42, green: 0.29, blue: 0.18, alpha: 1)
    static let rivalColors: [UIColor] = [
        UIColor(red: 1.00, green: 0.65, blue: 0.27, alpha: 1),  // P1 orange
        UIColor(red: 0.35, green: 0.55, blue: 0.90, alpha: 1),  // P2 blue
        UIColor(red: 0.60, green: 0.40, blue: 0.85, alpha: 1),  // P3 purple
        UIColor(red: 0.28, green: 0.75, blue: 0.60, alpha: 1),  // P4 teal
    ]
    static func rivalColor(_ id: Int) -> UIColor {
        rivalColors[((id % rivalColors.count) + rivalColors.count) % rivalColors.count]
    }
    static let carColors: [UIColor] = [
        UIColor(red: 0.90, green: 0.30, blue: 0.25, alpha: 1),
        UIColor(red: 0.98, green: 0.65, blue: 0.15, alpha: 1),
        UIColor(red: 0.35, green: 0.55, blue: 0.90, alpha: 1),
        UIColor(red: 0.60, green: 0.40, blue: 0.85, alpha: 1),
        UIColor(red: 0.28, green: 0.75, blue: 0.60, alpha: 1),
        UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1),
    ]
}

enum Dir {
    case forward, back, left, right

    /// World-space delta. Forward is +Z. With the camera at (-x, +y, -z),
    /// screen-right corresponds to world -X.
    var dx: Int {
        switch self {
        case .left: return 1
        case .right: return -1
        default: return 0
        }
    }
    var dz: Int {
        switch self {
        case .forward: return 1
        case .back: return -1
        default: return 0
        }
    }
    /// Yaw so the model (built facing +Z) faces the movement direction.
    var yaw: Float {
        switch self {
        case .forward: return 0
        case .back: return .pi
        case .left: return .pi / 2
        case .right: return -.pi / 2
        }
    }
}

extension Float {
    static func rand(_ range: ClosedRange<Float>) -> Float {
        Float.random(in: range)
    }
}
