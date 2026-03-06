import Testing
@testable import HabitStack

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
