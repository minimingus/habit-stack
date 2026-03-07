import Foundation
import Observation

@Observable
final class AnalyticsViewModel {
    var habits: [Habit] = []
    var selectedHabit: Habit?
    var logs: [HabitLog] = []
    var streak: Streak?
    var isLoading = false
    var isPro = false

    // Cross-habit analytics
    var allHabitsStats: [(habit: Habit, rate: Double)] = []
    var weeklyConsistencyRate: Double = 0

    func load() async {
        guard let userId = try? await supabase.auth.session.user.id else { return }
        isLoading = true
        isPro = RevenueCatManager.shared.isProUser
        habits = (try? await supabase
            .from("habits")
            .select()
            .eq("user_id", value: userId.uuidString)
            .is("archived_at", value: nil)
            .order("sort_order")
            .execute()
            .value) ?? []
        selectedHabit = selectedHabit ?? habits.first
        if let habit = selectedHabit {
            await loadLogs(for: habit, userId: userId)
        }
        await loadAllHabitsStats(userId: userId)
        isLoading = false
    }

    func select(habit: Habit) async {
        selectedHabit = habit
        guard let userId = try? await supabase.auth.session.user.id else { return }
        await loadLogs(for: habit, userId: userId)
    }

    private func loadLogs(for habit: Habit, userId: UUID) async {
        let days = isPro ? 35 : 7
        logs = (try? await HabitService.shared.fetchHistory(
            habitId: habit.id,
            userId: userId,
            days: days,
            isPro: isPro
        )) ?? []
        streak = try? await StreakService.shared.streak(for: habit.id)
    }

    private func loadAllHabitsStats(userId: UUID) async {
        guard !habits.isEmpty else { return }
        let formatter = ISO8601DateFormatter()
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        var stats: [(habit: Habit, rate: Double)] = []

        for habit in habits {
            let habitLogs: [HabitLog] = (try? await supabase
                .from("habit_logs")
                .select()
                .eq("habit_id", value: habit.id.uuidString)
                .gte("logged_at", value: formatter.string(from: weekAgo))
                .execute()
                .value) ?? []
            let doneCount = habitLogs.filter { $0.status == .done }.count
            stats.append((habit: habit, rate: Double(doneCount) / 7.0))
        }

        let avg = stats.isEmpty ? 0.0 : stats.map { $0.rate }.reduce(0, +) / Double(stats.count)
        await MainActor.run {
            self.allHabitsStats = stats.sorted { $0.rate > $1.rate }
            self.weeklyConsistencyRate = avg
        }
    }

    // MARK: - Computed analytics

    var strongestHabit: (habit: Habit, rate: Double)? { allHabitsStats.first }
    var weakestHabit: (habit: Habit, rate: Double)? { allHabitsStats.last }

    /// Completion count per day of week (Mon=0 … Sun=6) for selected habit
    var dayOfWeekCounts: [(day: String, count: Int)] {
        let labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let calendar = Calendar.current
        let doneLogs = logs.filter { $0.status == .done }
        var counts = Array(repeating: 0, count: 7)
        for log in doneLogs {
            let weekday = calendar.component(.weekday, from: log.loggedAt) // 1=Sun..7=Sat
            let idx = (weekday + 5) % 7 // convert to Mon=0..Sun=6
            counts[idx] += 1
        }
        return labels.enumerated().map { (i, label) in (day: label, count: counts[i]) }
    }

    /// 7-day completion rate for the selected habit
    var selectedHabitWeeklyRate: Double {
        guard let stat = allHabitsStats.first(where: { $0.habit.id == selectedHabit?.id }) else {
            return 0
        }
        return stat.rate
    }

    // MARK: - Heatmap

    func heatmapData() -> [(date: Date, status: HabitLog.Status?)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let logsByDate: [Date: HabitLog] = Dictionary(
            uniqueKeysWithValues: logs.compactMap { log -> (Date, HabitLog)? in
                let day = calendar.startOfDay(for: log.loggedAt)
                return (day, log)
            }
        )
        return (0..<35).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            return (date: date, status: logsByDate[date]?.status)
        }
    }
}
