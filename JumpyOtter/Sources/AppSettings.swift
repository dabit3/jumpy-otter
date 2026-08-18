import Foundation

/// Local, UserDefaults-backed app settings and profile.
final class AppSettings {
    static let shared = AppSettings()

    private let defaults = UserDefaults.standard
    private init() {}

    // MARK: Settings

    var soundEnabled: Bool {
        get { defaults.object(forKey: "soundEnabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "soundEnabled") }
    }

    /// Master volume multiplier (0...1) applied to every effect.
    var volume: Float {
        get { defaults.object(forKey: "soundVolume") as? Float ?? 1.0 }
        set { defaults.set(newValue, forKey: "soundVolume") }
    }

    // MARK: Profile

    var username: String {
        get { defaults.string(forKey: "username") ?? "OTTER" }
        set {
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            defaults.set(trimmed.isEmpty ? "OTTER" : trimmed, forKey: "username")
        }
    }

    // Read-only stats written by GameController.
    var bestScore: Int { defaults.integer(forKey: "best") }
    var totalCreatine: Int { defaults.integer(forKey: "totalCreatine") }
}
