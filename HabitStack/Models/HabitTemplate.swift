//
//  HabitTemplate.swift
//  Better You
//
//  Created by Symphony
//  Phase 2: Issue #17
//

import Foundation

/// Pre-built habit template with identity trait mapping
struct HabitTemplate: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let emoji: String
    let description: String
    let suggestedDuration: Int // minutes
    let category: HabitCategory
    let identityTraits: [IdentityTrait]
    let defaultTime: TimeOfDay
    
    init(
        id: UUID = UUID(),
        name: String,
        emoji: String,
        description: String,
        suggestedDuration: Int,
        category: HabitCategory,
        identityTraits: [IdentityTrait],
        defaultTime: TimeOfDay
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.description = description
        self.suggestedDuration = suggestedDuration
        self.category = category
        self.identityTraits = identityTraits
        self.defaultTime = defaultTime
    }
}

/// Time of day for habit scheduling
enum TimeOfDay: String, Codable {
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"
    case anytime = "Anytime"
    
    var timeRange: String {
        switch self {
        case .morning: return "6-9 AM"
        case .afternoon: return "12-3 PM"
        case .evening: return "6-9 PM"
        case .anytime: return "Flexible"
        }
    }
}

/// Habit category for organization
enum HabitCategory: String, Codable, CaseIterable, Identifiable {
    case health = "Health"
    case mindfulness = "Mindfulness"
    case productivity = "Productivity"
    case learning = "Learning"
    case social = "Social"
    case creative = "Creative"

    var id: String { rawValue }
    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .health: return "heart.fill"
        case .mindfulness: return "brain.head.profile"
        case .productivity: return "bolt.fill"
        case .learning: return "book.fill"
        case .social: return "person.2.fill"
        case .creative: return "paintbrush.fill"
        }
    }
}

/// A curated group of habit templates
struct StarterPack: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let templates: [HabitTemplate]
}
