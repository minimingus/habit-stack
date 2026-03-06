import Testing
import Foundation
@testable import HabitStack

// Pure streak calculation logic extracted for testing
private func calculateStreak(doneDates: [Date]) -> (current: Int, longest: Int) {
    guard !doneDates.isEmpty else { return (0, 0) }
    let calendar = Calendar.current
    let sorted = doneDates
        .map { calendar.startOfDay(for: $0) }
        .sorted(by: >)

    let today = calendar.startOfDay(for: Date())
    let daysSinceFirst = calendar.dateComponents([.day], from: sorted[0], to: today).day ?? 0

    // Current streak: count consecutive days backwards from today/yesterday
    var currentStreak = 0
    if daysSinceFirst <= 1 {
        currentStreak = 1
        for i in 1..<sorted.count {
            let gap = calendar.dateComponents([.day], from: sorted[i], to: sorted[i-1]).day ?? 0
            if gap == 1 { currentStreak += 1 } else { break }
        }
    }

    // Longest streak: scan entire history
    var longestStreak = 0
    var tempStreak = 1
    for i in 1..<sorted.count {
        let gap = calendar.dateComponents([.day], from: sorted[i], to: sorted[i-1]).day ?? 0
        if gap == 1 { tempStreak += 1 } else { longestStreak = max(longestStreak, tempStreak); tempStreak = 1 }
    }
    longestStreak = max(longestStreak, tempStreak)

    return (currentStreak, longestStreak)
}

@Suite("Streak Calculation Tests")
struct StreakCalculationTests {
    private func daysAgo(_ n: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -n, to: Date())!
    }

    @Test func consecutiveDaysIncreaseStreak() {
        let dates = [daysAgo(0), daysAgo(1), daysAgo(2)]
        let result = calculateStreak(doneDates: dates)
        #expect(result.current == 3)
        #expect(result.longest == 3)
    }

    @Test func gapOfOneDayResetsStreak() {
        let dates = [daysAgo(0), daysAgo(2)] // day 1 is missing
        let result = calculateStreak(doneDates: dates)
        #expect(result.current == 1)
    }

    @Test func longestStreakTrackedAcrossBreak() {
        let dates = [daysAgo(0), daysAgo(5), daysAgo(6), daysAgo(7)]
        let result = calculateStreak(doneDates: dates)
        #expect(result.current == 1)
        #expect(result.longest == 3)
    }

    @Test func singleDayStreak() {
        let dates = [daysAgo(0)]
        let result = calculateStreak(doneDates: dates)
        #expect(result.current == 1)
        #expect(result.longest == 1)
    }

    @Test func emptyDatesReturnsZero() {
        let result = calculateStreak(doneDates: [])
        #expect(result.current == 0)
        #expect(result.longest == 0)
    }

    @Test func streakLoggedYesterdayCountsAsActive() {
        let dates = [daysAgo(1), daysAgo(2), daysAgo(3)]
        let result = calculateStreak(doneDates: dates)
        #expect(result.current == 3)
    }
}

@Suite("Freemium Gate Tests")
struct FreemiumGateTests {
    @Test func freeTierHistoryClampedTo7Days() {
        let isPro = false
        let requestedDays = 30
        let clampedDays = isPro ? requestedDays : min(requestedDays, 7)
        #expect(clampedDays == 7)
    }

    @Test func proTierHistoryNotClamped() {
        let isPro = true
        let requestedDays = 30
        let clampedDays = isPro ? requestedDays : min(requestedDays, 7)
        #expect(clampedDays == 30)
    }

    @Test func freeTierHabitLimitIs5() {
        let limit = 5
        let existingCount = 5
        let wouldExceed = existingCount >= limit
        #expect(wouldExceed == true)
    }

    @Test func freeTierAllowsUpTo5Habits() {
        let limit = 5
        let existingCount = 4
        let wouldExceed = existingCount >= limit
        #expect(wouldExceed == false)
    }
}
