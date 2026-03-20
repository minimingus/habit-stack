import Foundation
import Observation
import Supabase
import PostHog

struct MonthlyRecapStats {
    let monthName: String
    let year: Int
    let overallCompletionRate: Double
    let totalCompleted: Int
    let totalPossible: Int
    let longestStreakAchieved: Int
    let identityVotesCast: Int
    let votesByTrait: [(trait: String, count: Int)]
    let topHabit: (name: String, emoji: String, rate: Double)?
    let trend: Trend
    let habitCount: Int

    enum Trend {
        case up, down, stable
    }
}

@Observable
final class MonthlyRecapViewModel {
    var stats: MonthlyRecapStats?
    var isLoading = false

    private static let iso = ISO8601DateFormatter()

    func load() async {
        guard let userId = try? await supabase.auth.session.user.id else { return }
        isLoading = true
        defer { isLoading = false }

        let calendar = Calendar.current
        let now = Date()

        // We show the recap for the PREVIOUS month
        guard let firstOfThisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let firstOfLastMonth = calendar.date(byAdding: .month, value: -1, to: firstOfThisMonth) else { return }

        let lastMonthComps = calendar.dateComponents([.year, .month], from: firstOfLastMonth)
        let monthName = calendar.monthSymbols[(lastMonthComps.month ?? 1) - 1]
        let year = lastMonthComps.year ?? calendar.component(.year, from: now)

        let startISO = Self.iso.string(from: firstOfLastMonth)
        let endISO = Self.iso.string(from: firstOfThisMonth)

        // Fetch habits (include archived — they may have logs from last month)
        let habits: [Habit] = (try? await supabase
            .from("habits")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value) ?? []

        // Fetch all logs for last month
        let logs: [HabitLog] = (try? await supabase
            .from("habit_logs")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("logged_at", value: startISO)
            .lt("logged_at", value: endISO)
            .execute()
            .value) ?? []

        // Fetch identity votes for last month
        let votes: [IdentityVote] = (try? await supabase
            .from("identity_votes")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("voted_at", value: startISO)
            .lt("voted_at", value: endISO)
            .execute()
            .value) ?? []

        // Fetch streaks for longest streak
        let streaks: [Streak] = (try? await supabase
            .from("streaks")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value) ?? []

        // Calculate days in last month
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfLastMonth)?.count ?? 30

        // Active habits that existed during the month (created before end of month, not archived before start)
        let activeHabits = habits.filter { habit in
            habit.createdAt < firstOfThisMonth &&
            (habit.archivedAt == nil || habit.archivedAt! > firstOfLastMonth)
        }

        let logsByHabit = Dictionary(grouping: logs, by: { $0.habitId })

        // Per-habit completion rates
        var habitRates: [(habit: Habit, doneCount: Int, rate: Double)] = []
        var totalDone = 0

        for habit in activeHabits {
            let habitLogs = logsByHabit[habit.id] ?? []
            let done = habitLogs.filter { $0.status == .done }.count
            totalDone += done
            let rate = Double(done) / Double(daysInMonth)
            habitRates.append((habit: habit, doneCount: done, rate: rate))
        }

        let totalPossible = activeHabits.count * daysInMonth
        let overallRate = totalPossible > 0 ? Double(totalDone) / Double(totalPossible) : 0

        // Top habit
        let topHabit = habitRates.max(by: { $0.rate < $1.rate })
        let topHabitResult: (name: String, emoji: String, rate: Double)? = topHabit.map {
            (name: $0.habit.name, emoji: $0.habit.emoji, rate: $0.rate)
        }

        // Longest streak
        let longestStreak = streaks.map(\.longestStreak).max() ?? 0

        // Identity votes by trait
        let votesByTrait = Dictionary(grouping: votes, by: { $0.identityStatement })
            .map { (trait: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }

        // Trend vs previous month
        let trend = await calculateTrend(
            userId: userId,
            currentRate: overallRate,
            twoMonthsAgoStart: calendar.date(byAdding: .month, value: -1, to: firstOfLastMonth)!,
            oneMonthAgoStart: firstOfLastMonth,
            activeHabitCount: activeHabits.count
        )

        let completedCount = totalDone
        await MainActor.run {
            self.stats = MonthlyRecapStats(
                monthName: monthName,
                year: year,
                overallCompletionRate: overallRate,
                totalCompleted: completedCount,
                totalPossible: totalPossible,
                longestStreakAchieved: longestStreak,
                identityVotesCast: votes.count,
                votesByTrait: votesByTrait,
                topHabit: topHabitResult,
                trend: trend,
                habitCount: activeHabits.count
            )
        }

        PostHogSDK.shared.capture("monthly_recap_shown", properties: [
            "month": monthName,
            "completion_rate": overallRate,
            "habit_count": activeHabits.count,
            "identity_votes": votes.count
        ])
    }

    private func calculateTrend(
        userId: UUID,
        currentRate: Double,
        twoMonthsAgoStart: Date,
        oneMonthAgoStart: Date,
        activeHabitCount: Int
    ) async -> MonthlyRecapStats.Trend {
        guard activeHabitCount > 0 else { return .stable }

        let prevLogs: [HabitLog] = (try? await supabase
            .from("habit_logs")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("logged_at", value: Self.iso.string(from: twoMonthsAgoStart))
            .lt("logged_at", value: Self.iso.string(from: oneMonthAgoStart))
            .execute()
            .value) ?? []

        let prevDone = prevLogs.filter { $0.status == .done }.count
        let daysInPrevMonth = Calendar.current.range(of: .day, in: .month, for: twoMonthsAgoStart)?.count ?? 30
        let prevRate = Double(prevDone) / Double(activeHabitCount * daysInPrevMonth)

        let diff = currentRate - prevRate
        if diff > 0.05 { return .up }
        if diff < -0.05 { return .down }
        return .stable
    }
}
