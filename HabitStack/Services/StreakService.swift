import Foundation
import Supabase

final class StreakService {
    static let shared = StreakService()
    private init() {}

    func fetchStreaks(userId: UUID) async throws -> [Streak] {
        return try await supabase
            .from("streaks")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
    }

    func streak(for habitId: UUID) async throws -> Streak {
        let streaks: [Streak] = try await supabase
            .from("streaks")
            .select()
            .eq("habit_id", value: habitId.uuidString)
            .limit(1)
            .execute()
            .value
        return streaks.first ?? Streak(
            habitId: habitId,
            userId: UUID(),
            currentStreak: 0,
            longestStreak: 0,
            lastLoggedDate: nil
        )
    }

    /// Check which habits are eligible for streak recovery and create recovery entries.
    func evaluateRecoveries(streaks: [Streak]) -> [UUID: StreakRecovery] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var active: [UUID: StreakRecovery] = [:]

        for streak in streaks {
            let habitId = streak.habitId

            // Already have an active recovery?
            if let existing = StreakRecovery.load(for: habitId) {
                if existing.isExpired && !existing.isComplete {
                    // Expired without completing — clear it
                    StreakRecovery.clear(for: habitId)
                } else if !existing.isComplete {
                    active[habitId] = existing
                }
                continue
            }

            // No active recovery — check if we should offer one
            guard let lastDate = streak.lastLoggedDate else { continue }
            let last = calendar.startOfDay(for: lastDate)
            let daysMissed = calendar.dateComponents([.day], from: last, to: today).day ?? 0

            // Eligible: missed exactly 1 day (yesterday was missed, last log was 2 days ago)
            // and had a streak worth recovering (>= 2)
            guard daysMissed == 2, streak.currentStreak >= 2 else { continue }
            guard !StreakRecovery.isOnCooldown(for: habitId) else { continue }

            let missedDay = calendar.date(byAdding: .day, value: -1, to: today)!
            let recovery = StreakRecovery(
                habitId: habitId,
                missedDate: missedDay,
                streakValueAtBreak: streak.currentStreak,
                startedAt: Date(),
                completedDays: 0
            )
            recovery.save()
            active[habitId] = recovery
        }

        return active
    }

    /// Record a recovery day completion. Returns the updated recovery.
    func advanceRecovery(for habitId: UUID) -> StreakRecovery? {
        guard var recovery = StreakRecovery.load(for: habitId) else { return nil }
        guard !recovery.isExpired, !recovery.isComplete else { return nil }
        recovery.completedDays += 1
        recovery.save()
        return recovery
    }

    /// Complete recovery by backfilling the missed day log.
    func completeRecovery(for habitId: UUID, userId: UUID) async throws {
        guard let recovery = StreakRecovery.load(for: habitId), recovery.isComplete else { return }

        // Backfill a 'done' log for the missed day — this triggers streak-calc
        // which will recalculate and see a continuous chain of completions.
        let formatter = ISO8601DateFormatter()
        let calendar = Calendar.current
        let missedNoon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: recovery.missedDate)!

        try await supabase
            .from("habit_logs")
            .insert([
                "habit_id": habitId.uuidString,
                "user_id": userId.uuidString,
                "logged_at": formatter.string(from: missedNoon),
                "status": "done"
            ])
            .execute()

        StreakRecovery.recordCooldown(for: habitId)
        StreakRecovery.clear(for: habitId)
    }
}
