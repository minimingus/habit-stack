import Foundation

struct Streak: Codable, Identifiable {
    var habitId: UUID
    var userId: UUID
    var currentStreak: Int
    var longestStreak: Int
    var lastLoggedDate: Date?

    var id: UUID { habitId }

    enum CodingKeys: String, CodingKey {
        case habitId = "habit_id"
        case userId = "user_id"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case lastLoggedDate = "last_logged_date"
    }
}
