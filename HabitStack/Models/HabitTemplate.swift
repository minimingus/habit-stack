import Foundation

enum HabitCategory: String, CaseIterable, Identifiable {
    case health = "Health"
    case mind = "Mind & Mental Health"
    case learning = "Learning"
    case productivity = "Productivity"
    case relationships = "Relationships"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .health: return "heart.fill"
        case .mind: return "brain.head.profile"
        case .learning: return "book.fill"
        case .productivity: return "checkmark.seal.fill"
        case .relationships: return "person.2.fill"
        }
    }
}

struct HabitTemplate: Identifiable {
    let id = UUID()
    let name: String
    let emoji: String
    let category: HabitCategory
    let identity: String
    let tinyVersion: String
    let cue: String
    let timeOfDay: Habit.TimeOfDay
    let reward: String
}

struct StarterPack: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let templates: [HabitTemplate]
}
