import Testing
@testable import HabitStack

// MARK: - ScorecardService (implementation lives here until project.pbxproj is regenerated via xcodegen)

enum ScorecardDimension { case sleep, movement, mind, growth }

struct ScorecardResult {
    let sleep: Int
    let movement: Int
    let mind: Int
    let growth: Int
    let recommended: ScorecardDimension
}

enum ScorecardService {
    static func calculate(sleep: Int, movement: Int, mind: Int, growth: Int) -> ScorecardResult {
        // Priority order for tie-breaking: sleep > movement > mind > growth
        let ranked: [(ScorecardDimension, Int)] = [
            (.sleep, sleep), (.movement, movement), (.mind, mind), (.growth, growth)
        ]
        let minScore = ranked.map(\.1).min() ?? 0
        let recommended = ranked.first(where: { $0.1 == minScore })!.0
        return ScorecardResult(sleep: sleep, movement: movement, mind: mind, growth: growth,
                               recommended: recommended)
    }
}

@Suite("Scorecard Service Tests")
struct ScorecardTests {

    // MARK: - Single dimension lowest

    @Test func scorecardRecommendsSleepWhenLowest() {
        let result = ScorecardService.calculate(sleep: 1, movement: 3, mind: 3, growth: 3)
        #expect(result.recommended == .sleep)
    }

    @Test func scorecardRecommendsMovementWhenLowest() {
        let result = ScorecardService.calculate(sleep: 3, movement: 1, mind: 3, growth: 3)
        #expect(result.recommended == .movement)
    }

    @Test func scorecardRecommendsMindWhenLowest() {
        let result = ScorecardService.calculate(sleep: 3, movement: 3, mind: 1, growth: 3)
        #expect(result.recommended == .mind)
    }

    @Test func scorecardRecommendsGrowthWhenLowest() {
        let result = ScorecardService.calculate(sleep: 3, movement: 3, mind: 3, growth: 1)
        #expect(result.recommended == .growth)
    }

    // MARK: - Tie-break scenarios

    @Test func sleepBeatsMovementInTie() {
        let result = ScorecardService.calculate(sleep: 1, movement: 1, mind: 3, growth: 3)
        #expect(result.recommended == .sleep)
    }

    @Test func sleepBeatsMindInTie() {
        let result = ScorecardService.calculate(sleep: 1, movement: 3, mind: 1, growth: 3)
        #expect(result.recommended == .sleep)
    }

    @Test func sleepBeatsGrowthInTie() {
        let result = ScorecardService.calculate(sleep: 1, movement: 3, mind: 3, growth: 1)
        #expect(result.recommended == .sleep)
    }

    @Test func movementBeatsMindInTie() {
        let result = ScorecardService.calculate(sleep: 3, movement: 1, mind: 1, growth: 3)
        #expect(result.recommended == .movement)
    }

    @Test func movementBeatsGrowthInTie() {
        let result = ScorecardService.calculate(sleep: 3, movement: 1, mind: 3, growth: 1)
        #expect(result.recommended == .movement)
    }

    @Test func mindBeatsGrowthInTie() {
        let result = ScorecardService.calculate(sleep: 3, movement: 3, mind: 1, growth: 1)
        #expect(result.recommended == .mind)
    }

    // MARK: - Equal scores → sleep wins

    @Test func allEqualScoresSleepWins() {
        let result = ScorecardService.calculate(sleep: 3, movement: 3, mind: 3, growth: 3)
        #expect(result.recommended == .sleep)
    }

    @Test func allLowEqualSleepWins() {
        let result = ScorecardService.calculate(sleep: 1, movement: 1, mind: 1, growth: 1)
        #expect(result.recommended == .sleep)
    }

    // MARK: - Scores stored correctly

    @Test func scoresStoredCorrectly() {
        let result = ScorecardService.calculate(sleep: 2, movement: 4, mind: 3, growth: 5)
        #expect(result.sleep == 2)
        #expect(result.movement == 4)
        #expect(result.mind == 3)
        #expect(result.growth == 5)
        #expect(result.recommended == .sleep)
    }
}
