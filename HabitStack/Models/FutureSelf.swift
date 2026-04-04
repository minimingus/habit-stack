//
//  FutureSelf.swift
//  Better You
//
//  Created by Symphony
//  Phase 2: Issue #16
//

import Foundation

/// User's selected identity traits - "Who do you want to become?"
struct FutureSelf: Codable, Identifiable, Equatable {
    let id: UUID
    var traits: [IdentityTrait]
    let createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(), traits: [IdentityTrait], createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.traits = traits
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Identity traits that define who the user wants to become
enum IdentityTrait: String, Codable, CaseIterable, Identifiable {
    case stronger = "💪 Stronger"
    case focused = "🧠 Focused"
    case energetic = "⚡ Energetic"
    case calmer = "😌 Calmer"
    case disciplined = "🎯 Disciplined"
    case confident = "🌟 Confident"
    case healthier = "🏃 Healthier"
    case productive = "💼 Productive"
    
    var id: String { rawValue }

    /// Display name without emoji prefix
    var displayName: String {
        String(rawValue.dropFirst(2))
    }

    /// SF Symbol for UI display
    var sfSymbol: String {
        switch self {
        case .stronger:     return "dumbbell"
        case .focused:      return "brain.head.profile"
        case .energetic:    return "bolt.fill"
        case .calmer:       return "wind"
        case .disciplined:  return "target"
        case .confident:    return "star.fill"
        case .healthier:    return "heart.fill"
        case .productive:   return "checkmark.circle.fill"
        }
    }
    
    /// Description/tagline for the trait
    var description: String {
        switch self {
        case .stronger:
            return "Build physical strength"
        case .focused:
            return "Sharpen your mental clarity"
        case .energetic:
            return "Boost your daily energy"
        case .calmer:
            return "Find inner peace"
        case .disciplined:
            return "Master self-control"
        case .confident:
            return "Believe in yourself"
        case .healthier:
            return "Improve your wellbeing"
        case .productive:
            return "Get more done"
        }
    }
}
