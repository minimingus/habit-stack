import Foundation
import Observation

enum NeverMissTwiceState {
    case warning, comeback, dismissed
}

private let milestoneValues: Set<Int> = [7, 14, 21, 30, 66, 100]

@Observable
final class TodayViewModel {
    var habitGroups: [Habit.TimeOfDay: [HabitWithStatus]] = [:]
    var isLoading = false
    var errorMessage: String?
    var streaks: [UUID: Streak] = [:]
    var showNeverMissTwice = false
    var neverMissTwiceDismissed = false
    var neverMissTwiceCount = 0
    var profile: Profile?
    var showXPToast = false
    var xpToastAmount = 10
    var xpToastIsIdentity = false
    var lastCompletedHabitName: String?
    var showMilestone = false
    var milestoneStreak = 0
    var milestoneHabitName = ""
    var topIdentityStatement: String?
    var neverMissTwiceState: NeverMissTwiceState = .dismissed
    var isPerfectDay = false

    private var userId: UUID?

    // MARK: - Computed

    var totalHabits: Int { habitGroups.values.flatMap { $0 }.count }
    var completedHabits: Int { habitGroups.values.flatMap { $0 }.filter { $0.isCompleted }.count }
    var progress: Double {
        guard totalHabits > 0 else { return 0 }
        return Double(completedHabits) / Double(totalHabits)
    }

    var momentumMessage: String {
        guard totalHabits > 0 else { return "" }
        switch progress {
        case 0: return "Let's get started!"
        case ..<0.5: return "Keep going!"
        case ..<1.0: return "Almost there!"
        default: return "Perfect day!"
        }
    }

    var orderedGroups: [(Habit.TimeOfDay, [HabitWithStatus])] {
        let order: [Habit.TimeOfDay] = [.morning, .allDay, .afternoon, .evening]
        return order.compactMap { tod in
            guard let habits = habitGroups[tod], !habits.isEmpty else { return nil }
            return (tod, habits)
        }
    }

    func moveHabits(in timeOfDay: Habit.TimeOfDay, from source: IndexSet, to destination: Int) {
        guard var group = habitGroups[timeOfDay] else { return }
        group.move(fromOffsets: source, toOffset: destination)
        habitGroups[timeOfDay] = group
        Task {
            try? await HabitService.shared.reorderHabits(group.map { $0.habit })
        }
    }

    // MARK: - Load

    func loadToday() async {
        guard let userId = try? await supabase.auth.session.user.id else { return }
        self.userId = userId
        isLoading = true
        defer { isLoading = false }
        do {
            let habits = try await HabitService.shared.fetchTodayHabits(userId: userId)
            let allStreaks = try await StreakService.shared.fetchStreaks(userId: userId)
            let profiles: [Profile] = (try? await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value) ?? []
            await MainActor.run {
                self.streaks = Dictionary(uniqueKeysWithValues: allStreaks.map { ($0.habitId, $0) })
                self.habitGroups = Dictionary(grouping: habits, by: { $0.habit.timeOfDay })
                self.profile = profiles.first
                self.checkNeverMissTwice(streaks: allStreaks)
                self.scheduleRetentionNotifications(habits: habits, streaks: allStreaks)
            }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }

    // MARK: - Toggle

    func toggleHabit(_ habitWithStatus: HabitWithStatus) async {
        guard let userId else { return }
        let habitId = habitWithStatus.habit.id
        let habitName = habitWithStatus.habit.name
        let newStatus: HabitLog.Status = habitWithStatus.isCompleted ? .skipped : .done

        // Optimistic update
        await MainActor.run {
            for key in habitGroups.keys {
                if let index = habitGroups[key]?.firstIndex(where: { $0.id == habitId }) {
                    habitGroups[key]?[index].isCompleted = !habitWithStatus.isCompleted
                }
            }
        }

        HapticManager.impact(.medium)

        do {
            try await HabitService.shared.logHabit(habitId: habitId, userId: userId, status: newStatus)
            let allStreaks = try await StreakService.shared.fetchStreaks(userId: userId)
            let profiles: [Profile] = (try? await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value) ?? []
            await MainActor.run {
                self.streaks = Dictionary(uniqueKeysWithValues: allStreaks.map { ($0.habitId, $0) })
                self.profile = profiles.first
                if newStatus == .done {
                    self.lastCompletedHabitName = habitName
                    let completedHabit = self.habitGroups.values.flatMap { $0 }.first { $0.habit.id == habitId }
                    self.topIdentityStatement = completedHabit?.habit.craving
                    self.showXPToastRotated()
                    self.checkMilestone(for: habitId, habitName: habitName, streaks: allStreaks)
                    self.checkPerfectDay()
                    self.checkComeback()
                    self.scheduleRetentionNotifications(
                        habits: self.habitGroups.values.flatMap { $0 }.map { $0 },
                        streaks: allStreaks
                    )
                }
            }
        } catch {
            await MainActor.run {
                for key in habitGroups.keys {
                    if let index = habitGroups[key]?.firstIndex(where: { $0.id == habitId }) {
                        habitGroups[key]?[index].isCompleted = habitWithStatus.isCompleted
                    }
                }
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Private helpers

    private func showXPToastRotated() {
        // Alternate between XP and identity message
        let showIdentity = (topIdentityStatement != nil) && (completedHabits % 2 == 0)
        xpToastIsIdentity = showIdentity
        showXPToast = true
    }

    private func checkMilestone(for habitId: UUID, habitName: String, streaks: [Streak]) {
        guard let streak = streaks.first(where: { $0.habitId == habitId }) else { return }
        let count = streak.currentStreak
        guard milestoneValues.contains(count) else { return }
        let key = "shownMilestone_\(habitId)_\(count)"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)
        UserDefaults.standard.set(true, forKey: "achievement_milestone_\(count)")
        milestoneStreak = count
        milestoneHabitName = habitName
        showMilestone = true
        HapticManager.notification(.success)
    }

    private func checkNeverMissTwice(streaks: [Streak]) {
        guard !neverMissTwiceDismissed, !streaks.isEmpty else { return }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let missedCount = streaks.filter { streak in
            guard let lastDate = streak.lastLoggedDate else { return false }
            let last = calendar.startOfDay(for: lastDate)
            let days = calendar.dateComponents([.day], from: last, to: today).day ?? 0
            return days >= 2
        }.count
        neverMissTwiceCount = missedCount
        let shouldShow = missedCount > 0 && missedCount > streaks.count / 2
        showNeverMissTwice = shouldShow
        neverMissTwiceState = shouldShow ? .warning : .dismissed
    }

    private func scheduleRetentionNotifications(habits: [HabitWithStatus], streaks: [Streak]) {
        let incomplete = habits.filter { !$0.isCompleted }
        NotificationManager.shared.scheduleEODRecovery(pendingCount: incomplete.count)

        let atRisk = streaks.compactMap { streak -> (name: String, streak: Int)? in
            guard streak.currentStreak > 0 else { return nil }
            let isComplete = habits.first { $0.habit.id == streak.habitId }?.isCompleted ?? true
            guard !isComplete else { return nil }
            let name = habits.first { $0.habit.id == streak.habitId }?.habit.name ?? "a habit"
            return (name: name, streak: streak.currentStreak)
        }
        NotificationManager.shared.scheduleStreakAtRisk(habits: atRisk)

        // Miss 2 days check
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let missed2Days = streaks.contains { streak in
            guard let lastDate = streak.lastLoggedDate else { return false }
            let last = calendar.startOfDay(for: lastDate)
            let days = calendar.dateComponents([.day], from: last, to: today).day ?? 0
            return days == 2
        }
        if missed2Days {
            NotificationManager.shared.scheduleMiss2DaysEncouragement()
        }
    }

    private func checkPerfectDay() {
        guard completedHabits == totalHabits, totalHabits > 0, !showMilestone else { return }
        let dateKey = "perfectDay_\(todayDateString)"
        guard !UserDefaults.standard.bool(forKey: dateKey) else { return }
        UserDefaults.standard.set(true, forKey: dateKey)
        UserDefaults.standard.set(true, forKey: "achievement_perfectDay")
        isPerfectDay = true
        milestoneStreak = 0  // 0 = perfect day sentinel
        milestoneHabitName = "Perfect Day"
        showMilestone = true
        HapticManager.notification(.success)
    }

    private func checkComeback() {
        guard neverMissTwiceState == .warning, completedHabits == 1 else { return }
        withAnimation { neverMissTwiceState = .comeback }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self else { return }
            withAnimation { self.neverMissTwiceState = .dismissed }
        }
    }

    private var todayDateString: String {
        String(ISO8601DateFormatter().string(from: Date()).prefix(10))
    }

    func spendStreakShield() async {
        guard let userId else { return }
        try? await supabase.rpc("spend_streak_shield", params: ["p_user_id": userId.uuidString]).execute()
        await loadToday()
        await MainActor.run {
            withAnimation { neverMissTwiceState = .comeback }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                guard let self else { return }
                withAnimation { self.neverMissTwiceState = .dismissed }
            }
        }
    }

}
