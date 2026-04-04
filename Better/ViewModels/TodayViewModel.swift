import Foundation
import Observation
import WidgetKit
import PostHog

enum NeverMissTwiceState: Equatable {
    case warning, comeback, dismissed
    case recovering(day: Int) // day 0, 1, or 2 of recovery
    case recoverySuccess
}

private let milestoneValues: Set<Int> = [7, 14, 21, 30, 66, 100]

@Observable
final class TodayViewModel {
    var habitGroups: [Habit.TimeOfDay: [HabitWithStatus]] = [:]
    var pausedHabits: [Habit] = []
    var isLoading = false
    var errorMessage: String?
    var streaks: [UUID: Streak] = [:]
    var neverMissTwiceDismissed = false
    var neverMissTwiceCount = 0
    var profile: Profile?
    var showXPToast = false
    var xpToastAmount = 10
    var lastCompletedHabitName: String?
    var showMilestone = false
    var milestoneStreak = 0
    var milestoneHabitName = ""
    var topIdentityStatement: String?
    var identityVoteCount: Int = 0
    var neverMissTwiceState: NeverMissTwiceState = .dismissed
    var isPerfectDay = false
    var activeRecoveries: [UUID: StreakRecovery] = [:]
    var recoveryHabitCount = 0

    private var userId: UUID?

    // MARK: - Computed

    var totalHabits: Int { habitGroups.values.flatMap { $0 }.count }
    var completedHabits: Int { habitGroups.values.flatMap { $0 }.filter { $0.isCompleted }.count }

    var isPaused: Bool { !pausedHabits.isEmpty }
    var progress: Double {
        guard totalHabits > 0 else { return 0 }
        return Double(completedHabits) / Double(totalHabits)
    }

    var momentumMessage: String {
        guard totalHabits > 0 else { return "" }
        switch progress {
        case 0: return "Start where you are."
        case ..<0.5: return "One at a time."
        case ..<1.0: return "Almost there."
        default: return "Every habit done."
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
            do {
                try await HabitService.shared.reorderHabits(group.map { $0.habit })
            } catch {
                await MainActor.run { errorMessage = "Couldn't save new order. It will reset on next launch." }
                PostHogSDK.shared.capture("error_occurred", properties: ["source": "reorder_habits", "message": error.localizedDescription])
            }
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
            let now = Date()
            await MainActor.run {
                self.streaks = Dictionary(uniqueKeysWithValues: allStreaks.map { ($0.habitId, $0) })
                let active = habits.filter {
                    ($0.habit.pausedUntil == nil || $0.habit.pausedUntil! <= now) &&
                    self.isScheduledToday($0.habit)
                }
                self.pausedHabits = habits
                    .filter { $0.habit.pausedUntil != nil && $0.habit.pausedUntil! > now }
                    .map { $0.habit }
                self.habitGroups = Dictionary(grouping: active, by: { $0.habit.timeOfDay })
                self.profile = profiles.first
                self.checkNeverMissTwice(streaks: allStreaks)
                self.scheduleRetentionNotifications(habits: active, streaks: allStreaks)
                self.schedulePredictiveNudges(for: active)
                self.updateWidgetData()
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
            if newStatus == .done {
                PostHogSDK.shared.capture("habit_completed", properties: ["habit_name": habitName])
            }
            let allStreaks = try await StreakService.shared.fetchStreaks(userId: userId)
            let profiles: [Profile] = (try? await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value) ?? []

            // Fetch identity vote count for the completed habit's identity statement
            var fetchedVoteCount = 0
            var identityTraitName: String?
            if newStatus == .done {
                let completedHabit = await MainActor.run {
                    self.habitGroups.values.flatMap { $0 }.first { $0.habit.id == habitId }
                }
                identityTraitName = completedHabit?.habit.craving
                if let statement = identityTraitName {
                    // Record identity vote for this habit completion
                    try? await supabase
                        .from("identity_votes")
                        .insert([
                            "user_id": userId.uuidString,
                            "habit_id": habitId.uuidString,
                            "identity_statement": statement
                        ])
                        .execute()

                    let allVotes: [IdentityVote] = (try? await supabase
                        .from("identity_votes")
                        .select()
                        .eq("user_id", value: userId.uuidString)
                        .execute()
                        .value) ?? []
                    let traitVotes = allVotes.filter {
                        $0.identityStatement.lowercased().trimmingCharacters(in: .whitespaces) == statement.lowercased().trimmingCharacters(in: .whitespaces)
                    }
                    fetchedVoteCount = traitVotes.count

                    // Identity analytics
                    PostHogSDK.shared.capture("identity_vote_cast", properties: [
                        "trait_name": statement,
                        "cumulative_count": fetchedVoteCount,
                        "habit_name": habitName
                    ])

                    let milestones: Set<Int> = [10, 25, 50, 100]
                    if milestones.contains(fetchedVoteCount) {
                        PostHogSDK.shared.capture("identity_evidence_milestone", properties: [
                            "trait_name": statement,
                            "milestone_count": fetchedVoteCount
                        ])
                    }

                    // Set user properties
                    let grouped = Dictionary(grouping: allVotes, by: { $0.identityStatement.lowercased().trimmingCharacters(in: .whitespaces) })
                    let identityDepth = grouped.values.filter { $0.count > 5 }.count
                    let topTrait = grouped.max(by: { $0.value.count < $1.value.count })?.value.first?.identityStatement ?? statement
                    PostHogSDK.shared.identify(userId.uuidString, userProperties: [
                        "identity_depth": identityDepth,
                        "top_identity_trait": topTrait
                    ])
                }
            }
            let voteCount = fetchedVoteCount

            await MainActor.run {
                self.streaks = Dictionary(uniqueKeysWithValues: allStreaks.map { ($0.habitId, $0) })
                self.profile = profiles.first
                self.updateWidgetData()
                if newStatus == .done {
                    self.recordCompletionHour(for: habitId)
                    NotificationManager.shared.cancelPredictiveNudge(for: habitId)
                    self.lastCompletedHabitName = habitName
                    let completedHabit = self.habitGroups.values.flatMap { $0 }.first { $0.habit.id == habitId }
                    self.topIdentityStatement = completedHabit?.habit.craving
                    self.identityVoteCount = voteCount
                    self.showXPToast = true
                    // Advance streak recovery if active
                    self.advanceRecoveryIfNeeded(habitId: habitId, habitName: habitName)
                    // checkMilestone must run before checkPerfectDay — perfect day guards on !showMilestone
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

    private func checkMilestone(for habitId: UUID, habitName: String, streaks: [Streak]) {
        guard let streak = streaks.first(where: { $0.habitId == habitId }) else { return }
        let count = streak.currentStreak
        guard milestoneValues.contains(count) else { return }
        let key = "shownMilestone_\(habitId)_\(count)"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)
        UserDefaults.standard.set(true, forKey: "achievement_milestone_\(count)")
        PostHogSDK.shared.capture("streak_milestone", properties: [
            "habit_name": habitName,
            "streak_days": count
        ])
        milestoneStreak = count
        milestoneHabitName = habitName
        showMilestone = true
        HapticManager.notification(.success)
    }

    private func checkNeverMissTwice(streaks: [Streak]) {
        guard !neverMissTwiceDismissed, !streaks.isEmpty else { return }

        // Check for expired recoveries and fire failure events
        for streak in streaks {
            if let existing = StreakRecovery.load(for: streak.habitId), existing.isExpired, !existing.isComplete {
                let habitName = habitGroups.values.flatMap { $0 }.first { $0.habit.id == streak.habitId }?.habit.name ?? "unknown"
                PostHogSDK.shared.capture("streak_recovery_failed", properties: [
                    "habit_name": habitName,
                    "streak_at_break": existing.streakValueAtBreak,
                    "days_completed": existing.completedDays
                ])
            }
        }

        // Evaluate streak recoveries
        let recoveries = StreakService.shared.evaluateRecoveries(streaks: streaks)
        self.activeRecoveries = recoveries
        self.recoveryHabitCount = recoveries.count

        // If any habits are in recovery, show recovery state
        if !recoveries.isEmpty {
            let maxDay = recoveries.values.map(\.completedDays).max() ?? 0
            neverMissTwiceState = .recovering(day: maxDay)

            // Fire offered event for newly created recoveries (completedDays == 0)
            for (habitId, recovery) in recoveries where recovery.completedDays == 0 {
                let habitName = habitGroups.values.flatMap { $0 }.first { $0.habit.id == habitId }?.habit.name ?? "unknown"
                PostHogSDK.shared.capture("streak_recovery_offered", properties: [
                    "habit_name": habitName,
                    "streak_at_break": recovery.streakValueAtBreak
                ])
            }
            return
        }

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
        // Recovery flow takes priority
        if case .recovering = neverMissTwiceState { return }

        guard neverMissTwiceState == .warning, completedHabits == 1 else { return }
        neverMissTwiceState = .comeback
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.neverMissTwiceState = .dismissed
        }
    }

    private func advanceRecoveryIfNeeded(habitId: UUID, habitName: String) {
        guard activeRecoveries[habitId] != nil else { return }
        guard let updated = StreakService.shared.advanceRecovery(for: habitId) else { return }
        activeRecoveries[habitId] = updated

        if updated.isComplete {
            // Recovery succeeded — backfill the missed day
            let uid = self.userId!
            PostHogSDK.shared.capture("streak_recovery_completed", properties: [
                "habit_name": habitName,
                "recovered_streak": updated.streakValueAtBreak
            ])
            neverMissTwiceState = .recoverySuccess
            HapticManager.notification(.success)
            Task {
                try? await StreakService.shared.completeRecovery(for: habitId, userId: uid)
                let refreshed = try? await StreakService.shared.fetchStreaks(userId: uid)
                await MainActor.run {
                    if let refreshed {
                        self.streaks = Dictionary(uniqueKeysWithValues: refreshed.map { ($0.habitId, $0) })
                    }
                    self.activeRecoveries.removeValue(forKey: habitId)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
                        if case .recoverySuccess = self?.neverMissTwiceState {
                            self?.neverMissTwiceState = .dismissed
                        }
                    }
                }
            }
        } else {
            neverMissTwiceState = .recovering(day: updated.completedDays)
            PostHogSDK.shared.capture("streak_recovery_day_completed", properties: [
                "habit_name": habitName,
                "recovery_day": updated.completedDays,
                "streak_at_break": updated.streakValueAtBreak
            ])
        }
    }

    private var todayDateString: String {
        String(ISO8601DateFormatter().string(from: Date()).prefix(10))
    }

    // MARK: - Predictive nudge helpers

    private func recordCompletionHour(for habitId: UUID) {
        let key = "completionHours_\(habitId.uuidString)"
        var hours = UserDefaults.standard.array(forKey: key) as? [Int] ?? []
        hours.append(Calendar.current.component(.hour, from: Date()))
        if hours.count > 14 { hours.removeFirst(hours.count - 14) }
        UserDefaults.standard.set(hours, forKey: key)
    }

    private func typicalCompletionHour(for habitId: UUID) -> Int? {
        let key = "completionHours_\(habitId.uuidString)"
        let hours = UserDefaults.standard.array(forKey: key) as? [Int] ?? []
        guard hours.count >= 5 else { return nil }
        let counts = Dictionary(grouping: hours, by: { $0 }).mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value })?.key
    }

    private func schedulePredictiveNudges(for habits: [HabitWithStatus]) {
        for hw in habits where !hw.isCompleted {
            if let hour = typicalCompletionHour(for: hw.habit.id) {
                NotificationManager.shared.schedulePredictiveNudge(for: hw.habit, typicalHour: hour)
            }
        }
    }

    // MARK: - Frequency filter

    private func isScheduledToday(_ habit: Habit) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: Date()) // 1=Sun…7=Sat
        switch habit.frequency {
        case .daily:    return true
        case .weekdays: return weekday >= 2 && weekday <= 6
        case .weekends: return weekday == 1 || weekday == 7
        case .custom:
            let days = UserDefaults.standard.array(forKey: "customDays_\(habit.id.uuidString)") as? [Int] ?? []
            return days.isEmpty || days.contains(weekday)
        }
    }

    private func updateWidgetData() {
        let defaults = UserDefaults(suiteName: "group.com.tomerab.better") ?? .standard
        defaults.set(completedHabits, forKey: "widget.completedCount")
        defaults.set(totalHabits, forKey: "widget.totalCount")
        WidgetCenter.shared.reloadTimelines(ofKind: "HabitProgressWidget")
    }

    func pauseHabit(_ habit: Habit, until: Date) async {
        do {
            try await HabitService.shared.pauseHabit(habit.id, until: until)
        } catch {
            await MainActor.run { errorMessage = "Couldn't pause habit. Please try again." }
            PostHogSDK.shared.capture("error_occurred", properties: ["source": "pause_habit", "message": error.localizedDescription])
        }
        await loadToday()
    }

    func resumeHabit(_ habit: Habit) async {
        guard let userId else { return }
        do {
            try await HabitService.shared.resumeHabit(habit.id, userId: userId, pausedUntil: habit.pausedUntil ?? Date())
        } catch {
            await MainActor.run { errorMessage = "Couldn't resume habit. Please try again." }
            PostHogSDK.shared.capture("error_occurred", properties: ["source": "resume_habit", "message": error.localizedDescription])
        }
        await loadToday()
    }

    func dismissNeverMissTwice() {
        neverMissTwiceDismissed = true
        neverMissTwiceState = .dismissed
    }

    func spendStreakShield() async {
        guard let userId else { return }
        do {
            try await supabase.rpc("spend_streak_shield", params: ["p_user_id": userId.uuidString]).execute()
            await loadToday()
            neverMissTwiceState = .comeback
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.neverMissTwiceState = .dismissed
            }
        } catch {
            await MainActor.run { errorMessage = "Couldn't activate streak shield. Please try again." }
            PostHogSDK.shared.capture("error_occurred", properties: ["source": "streak_shield", "message": error.localizedDescription])
        }
    }

}
