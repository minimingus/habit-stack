import Foundation

struct ScorecardResult: Codable, Hashable {
    var sleep: Int
    var movement: Int
    var mind: Int
    var growth: Int
    var recommended: Dimension

    enum Dimension: String, Codable, CaseIterable, Hashable {
        case sleep, movement, mind, growth

        var displayName: String {
            switch self {
            case .sleep: return "Sleep"
            case .movement: return "Movement"
            case .mind: return "Mind"
            case .growth: return "Growth"
            }
        }

        var icon: String {
            switch self {
            case .sleep: return "moon.fill"
            case .movement: return "figure.walk"
            case .mind: return "brain.head.profile"
            case .growth: return "book.fill"
            }
        }
    }
}

struct HabitTemplate {
    let name: String
    let emoji: String
    let tinyVersion: String
    let craving: String
    let routine: String
    let reward: String
    let timeOfDay: Habit.TimeOfDay
    let dimension: ScorecardResult.Dimension
}
