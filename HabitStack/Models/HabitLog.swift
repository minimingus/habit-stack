import Foundation

struct HabitLog: Codable, Identifiable {
    var id: UUID
    var habitId: UUID
    var userId: UUID
    var loggedAt: Date
    var status: Status
    var note: String?
    var mood: Int?

    enum Status: String, Codable {
        case done, skipped, missed
    }

    enum CodingKeys: String, CodingKey {
        case id, status, note, mood
        case habitId = "habit_id"
        case userId = "user_id"
        case loggedAt = "logged_at"
    }
}
