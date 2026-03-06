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
        isLoading = false
        if let habit = selectedHabit {
            await loadLogs(for: habit, userId: userId)
        }
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

    // Heatmap: 35-cell grid (5 weeks)
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
