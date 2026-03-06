import Foundation
import Observation

@Observable
final class TodayViewModel {
    var habitGroups: [Habit.TimeOfDay: [HabitWithStatus]] = [:]
    var isLoading = false
    var errorMessage: String?
    var streaks: [UUID: Streak] = [:]
    var showNeverMissTwice = false
    var neverMissTwiceDismissed = false
    var profile: Profile?
    var showXPToast = false
    var xpToastAmount = 10

    private var userId: UUID?

    func loadToday() async {
        print("[TodayVM] loadToday() called")
        guard let userId = try? await supabase.auth.session.user.id else {
            print("[TodayVM] ERROR: no session")
            return
        }
        self.userId = userId
        isLoading = true
        defer { isLoading = false }
        do {
            print("[TodayVM] fetching habits")
            let habits = try await HabitService.shared.fetchTodayHabits(userId: userId)
            print("[TodayVM] fetched \(habits.count) habits")
            print("[TodayVM] fetching streaks")
            let allStreaks = try await StreakService.shared.fetchStreaks(userId: userId)
            print("[TodayVM] fetched \(allStreaks.count) streaks")
            print("[TodayVM] fetching profile")
            let profiles: [Profile] = (try? await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value) ?? []
            print("[TodayVM] fetched profile: \(profiles.first != nil)")
            await MainActor.run {
                self.streaks = Dictionary(uniqueKeysWithValues: allStreaks.map { ($0.habitId, $0) })
                self.habitGroups = Dictionary(grouping: habits, by: { $0.habit.timeOfDay })
                self.profile = profiles.first
                self.checkNeverMissTwice(streaks: allStreaks)
            }
            print("[TodayVM] loading identity")
            await loadTopIdentity(userId: userId)
            print("[TodayVM] loadToday complete")
        } catch {
            print("[TodayVM] loadToday error: \(error)")
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }

    private func checkNeverMissTwice(streaks: [Streak]) {
        guard !neverMissTwiceDismissed else { return }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let missedYesterday = streaks.contains { streak in
            guard let lastDate = streak.lastLoggedDate else { return false }
            let last = calendar.startOfDay(for: lastDate)
            let days = calendar.dateComponents([.day], from: last, to: today).day ?? 0
            return days >= 2
        }
        showNeverMissTwice = missedYesterday
    }

    var topIdentityStatement: String?

    private func loadTopIdentity(userId: UUID) async {
        let votes: [IdentityVote] = (try? await supabase
            .from("identity_votes")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value) ?? []
        let grouped = Dictionary(grouping: votes, by: { $0.identityStatement })
        let top = grouped.max(by: { $0.value.count < $1.value.count })?.key
        await MainActor.run { self.topIdentityStatement = top }
    }

    func toggleHabit(_ habitWithStatus: HabitWithStatus) async {
        guard let userId else { return }
        let habitId = habitWithStatus.habit.id
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
            // Reload streaks after logging
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
                    self.showXPToast = true
                }
            }
        } catch {
            // Revert optimistic update on failure
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

    var totalHabits: Int { habitGroups.values.flatMap { $0 }.count }
    var completedHabits: Int { habitGroups.values.flatMap { $0 }.filter { $0.isCompleted }.count }
    var progress: Double {
        guard totalHabits > 0 else { return 0 }
        return Double(completedHabits) / Double(totalHabits)
    }

    var orderedGroups: [(Habit.TimeOfDay, [HabitWithStatus])] {
        let order: [Habit.TimeOfDay] = [.morning, .allDay, .afternoon, .evening]
        return order.compactMap { tod in
            guard let habits = habitGroups[tod], !habits.isEmpty else { return nil }
            return (tod, habits)
        }
    }
}
