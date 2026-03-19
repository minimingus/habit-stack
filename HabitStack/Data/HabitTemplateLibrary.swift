//
//  HabitTemplateLibrary.swift
//  Better You
//
//  Created by Symphony
//  Phase 2: Issue #17
//

import Foundation

/// Curated library of habit templates
struct HabitTemplateLibrary {
    
    /// All available habit templates
    static let all: [HabitTemplate] = [
        // HEALTH & FITNESS
        HabitTemplate(
            name: "Morning Walk",
            emoji: "🏃",
            description: "Start your day strong",
            suggestedDuration: 15,
            category: .health,
            identityTraits: [.stronger, .energetic, .healthier],
            defaultTime: .morning
        ),
        HabitTemplate(
            name: "Drink Water",
            emoji: "💧",
            description: "Stay hydrated",
            suggestedDuration: 1,
            category: .health,
            identityTraits: [.healthier, .energetic],
            defaultTime: .morning
        ),
        HabitTemplate(
            name: "Stretch",
            emoji: "🧘",
            description: "Loosen up your body",
            suggestedDuration: 5,
            category: .health,
            identityTraits: [.healthier, .calmer],
            defaultTime: .morning
        ),
        HabitTemplate(
            name: "Workout",
            emoji: "💪",
            description: "Build strength",
            suggestedDuration: 30,
            category: .health,
            identityTraits: [.stronger, .disciplined, .healthier],
            defaultTime: .morning
        ),
        
        // MINDFULNESS
        HabitTemplate(
            name: "2-Minute Breathing",
            emoji: "🧘‍♂️",
            description: "Clear your mind",
            suggestedDuration: 2,
            category: .mindfulness,
            identityTraits: [.focused, .calmer],
            defaultTime: .morning
        ),
        HabitTemplate(
            name: "Meditation",
            emoji: "🕉️",
            description: "Find inner peace",
            suggestedDuration: 10,
            category: .mindfulness,
            identityTraits: [.calmer, .focused, .disciplined],
            defaultTime: .morning
        ),
        HabitTemplate(
            name: "Gratitude Journal",
            emoji: "🙏",
            description: "Reflect on the good",
            suggestedDuration: 5,
            category: .mindfulness,
            identityTraits: [.calmer, .confident],
            defaultTime: .evening
        ),
        
        // PRODUCTIVITY
        HabitTemplate(
            name: "Plan Your Day",
            emoji: "📝",
            description: "Set daily priorities",
            suggestedDuration: 5,
            category: .productivity,
            identityTraits: [.productive, .disciplined, .focused],
            defaultTime: .morning
        ),
        HabitTemplate(
            name: "Deep Work Block",
            emoji: "🎯",
            description: "Focus on one task",
            suggestedDuration: 60,
            category: .productivity,
            identityTraits: [.productive, .focused, .disciplined],
            defaultTime: .morning
        ),
        HabitTemplate(
            name: "Review Your Day",
            emoji: "📊",
            description: "Reflect on progress",
            suggestedDuration: 5,
            category: .productivity,
            identityTraits: [.productive, .disciplined],
            defaultTime: .evening
        ),
        
        // LEARNING
        HabitTemplate(
            name: "Read 10 Pages",
            emoji: "📖",
            description: "Expand your knowledge",
            suggestedDuration: 15,
            category: .learning,
            identityTraits: [.focused, .disciplined, .productive],
            defaultTime: .evening
        ),
        HabitTemplate(
            name: "Learn Something New",
            emoji: "🎓",
            description: "Grow every day",
            suggestedDuration: 20,
            category: .learning,
            identityTraits: [.focused, .productive, .confident],
            defaultTime: .afternoon
        ),
        HabitTemplate(
            name: "Practice a Skill",
            emoji: "🎸",
            description: "Build mastery",
            suggestedDuration: 30,
            category: .learning,
            identityTraits: [.disciplined, .confident, .focused],
            defaultTime: .afternoon
        ),
        
        // SOCIAL
        HabitTemplate(
            name: "Call a Friend",
            emoji: "📞",
            description: "Stay connected",
            suggestedDuration: 10,
            category: .social,
            identityTraits: [.confident, .calmer],
            defaultTime: .evening
        ),
        HabitTemplate(
            name: "Quality Time",
            emoji: "👨‍👩‍👧‍👦",
            description: "Connect with loved ones",
            suggestedDuration: 30,
            category: .social,
            identityTraits: [.confident, .calmer],
            defaultTime: .evening
        ),
        
        // CREATIVE
        HabitTemplate(
            name: "Write",
            emoji: "✍️",
            description: "Express yourself",
            suggestedDuration: 15,
            category: .creative,
            identityTraits: [.focused, .confident, .productive],
            defaultTime: .evening
        ),
        HabitTemplate(
            name: "Create Art",
            emoji: "🎨",
            description: "Make something beautiful",
            suggestedDuration: 30,
            category: .creative,
            identityTraits: [.focused, .confident, .calmer],
            defaultTime: .afternoon
        ),
    ]
    
    /// Filter templates by identity traits
    static func filtered(by traits: [IdentityTrait]) -> [HabitTemplate] {
        guard !traits.isEmpty else { return all }
        
        return all.filter { template in
            !Set(template.identityTraits).isDisjoint(with: Set(traits))
        }
        .sorted { lhs, rhs in
            // Sort by number of matching traits (descending)
            let lhsMatches = Set(lhs.identityTraits).intersection(Set(traits)).count
            let rhsMatches = Set(rhs.identityTraits).intersection(Set(traits)).count
            return lhsMatches > rhsMatches
        }
    }
    
    /// Get random templates for onboarding
    static func randomSuggestions(for traits: [IdentityTrait], count: Int = 10) -> [HabitTemplate] {
        let filtered = filtered(by: traits)
        return Array(filtered.shuffled().prefix(count))
    }

    /// Filter templates by category
    static func templates(for category: HabitCategory) -> [HabitTemplate] {
        all.filter { $0.category == category }
    }

    /// Curated starter packs for quick onboarding
    static let starterPacks: [StarterPack] = [
        StarterPack(
            name: "Better Mornings",
            icon: "sunrise.fill",
            templates: all.filter { $0.defaultTime == .morning }.prefix(3).map { $0 }
        ),
        StarterPack(
            name: "Calm Mind",
            icon: "brain.head.profile",
            templates: all.filter { $0.category == .mindfulness }
        ),
        StarterPack(
            name: "Productive Days",
            icon: "bolt.fill",
            templates: all.filter { $0.category == .productivity }.prefix(3).map { $0 }
        ),
    ]
}
