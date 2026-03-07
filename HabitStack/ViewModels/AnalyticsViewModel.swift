import Foundation
import Observation

enum CalendarDayStatus {
    case full     // all habits logged 'done'
    case partial  // at least one habit logged 'done'
    case empty    // no habits logged 'done'
}

@MainActor
@Observable final class AnalyticsViewModel {
    var habits: [Habit] = []
    var selectedHabit: Habit?
    var logs: [HabitLog] = []
    var streak: Streak?
    var isLoading = false
    var isPro = false

    // Cross-habit analytics
    var allHabitsStats: [(habit: Habit, rate: Double)] = []
    var weeklyConsistencyRate: Double = 0

    // Calendar + best time of day
    var calendarData: [Date: CalendarDayStatus] = [:]
    var bestTimeOfDay: Habit.TimeOfDay? = nil

    // Collected logs across all habits (populated by loadAllHabitsStats)
    private var allLogs: [HabitLog] = []

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
        let days = isPro ? 35 : 7
        let weekAgo = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        var stats: [(habit: Habit, rate: Double)] = []
        var collected: [HabitLog] = []

        for habit in habits {
            let habitLogs: [HabitLog] = (try? await supabase
                .from("habit_logs")
                .select()
                .eq("habit_id", value: habit.id.uuidString)
                .gte("logged_at", value: formatter.string(from: weekAgo))
                .execute()
                .value) ?? []
            collected.append(contentsOf: habitLogs)
            let doneCount = habitLogs.filter { $0.status == .done }.count
            stats.append((habit: habit, rate: Double(doneCount) / Double(days)))
        }

        let avg = stats.isEmpty ? 0.0 : stats.map { $0.rate }.reduce(0, +) / Double(stats.count)
        await MainActor.run {
            self.allLogs = collected
            self.allHabitsStats = stats.sorted { $0.rate > $1.rate }
            self.weeklyConsistencyRate = avg
        }
        await loadCalendarData(userId: userId)
        computeBestTimeOfDay()
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

    // MARK: - Calendar Data

    func loadCalendarData(userId: UUID) async {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        let startOfNextMonth = calendar.date(byAdding: DateComponents(month: 1), to: startOfMonth)!
        let formatter = ISO8601DateFormatter()

        let monthLogs: [HabitLog] = (try? await supabase
            .from("habit_logs")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("logged_at", value: formatter.string(from: startOfMonth))
            .lt("logged_at", value: formatter.string(from: startOfNextMonth))
            .eq("status", value: "done")
            .execute()
            .value) ?? []

        guard let range = calendar.range(of: .day, in: .month, for: Date()) else { return }
        let totalHabits = habits.count

        // Pre-group done logs by calendar day to avoid O(n×days) scan
        var logsByDay: [Date: Set<UUID>] = [:]
        for log in monthLogs {
            let day = calendar.startOfDay(for: log.loggedAt)
            logsByDay[day, default: []].insert(log.habitId)
        }

        var result: [Date: CalendarDayStatus] = [:]
        for day in range {
            guard let date = calendar.date(bySetting: .day, value: day, of: startOfMonth) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            let uniqueDone = logsByDay[dayStart] ?? []
            let doneCount = uniqueDone.count
            let status: CalendarDayStatus
            if doneCount == totalHabits && totalHabits > 0 {
                status = .full
            } else if doneCount > 0 {
                status = .partial
            } else {
                status = .empty
            }
            result[dayStart] = status
        }

        await MainActor.run {
            self.calendarData = result
        }
    }

    // MARK: - Best Time of Day

    private func computeBestTimeOfDay() {
        // Precondition: allLogs must be populated by loadAllHabitsStats before calling this method.
        guard !habits.isEmpty else { bestTimeOfDay = nil; return }
        var rates: [Habit.TimeOfDay: Double] = [:]
        for tod in Habit.TimeOfDay.allCases {
            let todHabits = habits.filter { $0.timeOfDay == tod }
            guard !todHabits.isEmpty else { continue }
            let todIds = Set(todHabits.map { $0.id })
            let doneLogs = allLogs.filter { todIds.contains($0.habitId) && $0.status == .done }
            let totalLogs = allLogs.filter { todIds.contains($0.habitId) }
            guard !totalLogs.isEmpty else { continue }
            rates[tod] = Double(doneLogs.count) / Double(totalLogs.count)
        }
        bestTimeOfDay = rates.max(by: { $0.value < $1.value })?.key
    }
}
