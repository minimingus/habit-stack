import Foundation

struct Habit: Codable, Identifiable, Hashable {
    var id: UUID
    var userId: UUID
    var name: String
    var emoji: String
    var color: String
    var cue: String?
    var craving: String?
    var routine: String?
    var reward: String?
    var tinyVersion: String?
    var anchorHabitId: UUID?
    var frequency: Frequency
    var timeOfDay: TimeOfDay
    var reminderEnabled: Bool
    var reminderTime: Date?
    var archivedAt: Date?
    var pausedUntil: Date?
    var sortOrder: Int
    var createdAt: Date

    enum Frequency: String, Codable, CaseIterable {
        case daily, weekdays, weekends, custom
    }

    enum TimeOfDay: String, Codable, CaseIterable {
        case morning, afternoon, evening
        case allDay = "all-day"

        var displayName: String {
            switch self {
            case .morning: return "Morning"
            case .afternoon: return "Afternoon"
            case .evening: return "Evening"
            case .allDay: return "All Day"
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, name, emoji, color, cue, craving, routine, reward
        case userId = "user_id"
        case tinyVersion = "tiny_version"
        case anchorHabitId = "anchor_habit_id"
        case frequency
        case timeOfDay = "time_of_day"
        case reminderEnabled = "reminder_enabled"
        case reminderTime = "reminder_time"
        case archivedAt = "archived_at"
        case pausedUntil = "paused_until"
        case sortOrder = "sort_order"
        case createdAt = "created_at"
    }
}

struct HabitWithStatus: Identifiable {
    let habit: Habit
    var isCompleted: Bool
    var log: HabitLog?

    var id: UUID { habit.id }
}
