import Foundation

enum ScorecardService {
    static func calculate(sleep: Int, movement: Int, mind: Int, growth: Int) -> ScorecardResult {
        let scores: [(ScorecardResult.Dimension, Int)] = [
            (.sleep, sleep),
            (.movement, movement),
            (.mind, mind),
            (.growth, growth)
        ]
        // Tie-break order: sleep → movement → mind → growth (first in array wins)
        let recommended = scores.min(by: { $0.1 < $1.1 })!.0
        return ScorecardResult(
            sleep: sleep,
            movement: movement,
            mind: mind,
            growth: growth,
            recommended: recommended
        )
    }

    static func templateHabit(for dimension: ScorecardResult.Dimension) -> HabitTemplate {
        switch dimension {
        case .sleep:
            return HabitTemplate(
                name: "Wind-Down Routine",
                emoji: "\u{1F319}",
                tinyVersion: "Put my phone face-down for 5 minutes",
                craving: "I want to wake up feeling rested and clear-headed",
                routine: "Dim lights, put phone away, do light stretching",
                reward: "5 minutes of reading something enjoyable",
                timeOfDay: .evening,
                dimension: .sleep
            )
        case .movement:
            return HabitTemplate(
                name: "Daily Walk",
                emoji: "\u{1F6B6}",
                tinyVersion: "Put on my shoes and step outside",
                craving: "I want to feel energized and clear my head",
                routine: "10-minute walk around the block, no phone",
                reward: "A favorite podcast episode or music playlist",
                timeOfDay: .morning,
                dimension: .movement
            )
        case .mind:
            return HabitTemplate(
                name: "Mindful Breathing",
                emoji: "\u{1F9D8}",
                tinyVersion: "Take 3 slow deep breaths",
                craving: "I want to feel calm and focused throughout the day",
                routine: "5 minutes of box breathing or guided meditation",
                reward: "A moment of stillness before checking my phone",
                timeOfDay: .morning,
                dimension: .mind
            )
        case .growth:
            return HabitTemplate(
                name: "Read Daily",
                emoji: "\u{1F4DA}",
                tinyVersion: "Read one page",
                craving: "I want to keep learning and feel mentally sharp",
                routine: "Read for 10 minutes before bed or after lunch",
                reward: "Note one interesting idea I learned",
                timeOfDay: .evening,
                dimension: .growth
            )
        }
    }
}
