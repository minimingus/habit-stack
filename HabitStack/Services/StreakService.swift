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
}
