import Foundation

struct StreakRecovery: Codable {
    let habitId: UUID
    let missedDate: Date
    let streakValueAtBreak: Int
    let startedAt: Date
    var completedDays: Int // 0, 1, or 2

    var isExpired: Bool {
        Date().timeIntervalSince(startedAt) > 48 * 3600
    }

    var isComplete: Bool { completedDays >= 2 }

    // MARK: - UserDefaults persistence

    private static func key(for habitId: UUID) -> String {
        "streak_recovery_\(habitId.uuidString)"
    }

    private static func cooldownKey(for habitId: UUID) -> String {
        "streak_recovery_cooldown_\(habitId.uuidString)"
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.key(for: habitId))
    }

    static func load(for habitId: UUID) -> StreakRecovery? {
        guard let data = UserDefaults.standard.data(forKey: key(for: habitId)) else { return nil }
        return try? JSONDecoder().decode(StreakRecovery.self, from: data)
    }

    static func clear(for habitId: UUID) {
        UserDefaults.standard.removeObject(forKey: key(for: habitId))
    }

    static func recordCooldown(for habitId: UUID) {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: cooldownKey(for: habitId))
    }

    static func isOnCooldown(for habitId: UUID) -> Bool {
        let lastUsed = UserDefaults.standard.double(forKey: cooldownKey(for: habitId))
        guard lastUsed > 0 else { return false }
        return Date().timeIntervalSince1970 - lastUsed < 30 * 24 * 3600 // 30 days
    }
}
