import UserNotifications
import UIKit
import Supabase

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func scheduleReminder(for habit: Habit, streak: Streak? = nil) {
        guard habit.reminderEnabled, let reminderTime = habit.reminderTime else { return }
        let content = UNMutableNotificationContent()
        content.title = "\(habit.emoji) \(habit.name)"

        if let streak, streak.currentStreak > 0 {
            content.body = "Don't break your \(streak.currentStreak)-day streak!"
        } else if let tiny = habit.tinyVersion, !tiny.isEmpty {
            content.body = "Takes just 2 minutes: \(tiny)"
        } else {
            content.body = "Time for your habit!"
        }

        content.sound = .default

        let calendar = Calendar.current
        var components = calendar.dateComponents([.hour, .minute], from: reminderTime)
        components.second = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: habit.id.uuidString,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    func cancelReminder(for habitId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [habitId.uuidString]
        )
    }

    func rescheduleAll(habits: [Habit], streaks: [UUID: Streak] = [:]) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        habits.filter { $0.reminderEnabled }.forEach { scheduleReminder(for: $0, streak: streaks[$0.id]) }
    }

    // MARK: - Retention notifications

    func scheduleEODRecovery(pendingCount: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["eod-recovery"])
        guard pendingCount > 0 else { return }
        let content = UNMutableNotificationContent()
        content.title = "Don't end the day empty"
        content.body = "You have \(pendingCount) habit\(pendingCount == 1 ? "" : "s") left to complete today."
        content.sound = .default
        var comps = DateComponents()
        comps.hour = 21
        comps.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        center.add(UNNotificationRequest(identifier: "eod-recovery", content: content, trigger: trigger))
    }

    func scheduleStreakAtRisk(habits: [(name: String, streak: Int)]) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["streak-at-risk"])
        guard !habits.isEmpty else { return }
        let content = UNMutableNotificationContent()
        if habits.count == 1 {
            content.title = "Streak at risk"
            content.body = "Don't break your \(habits[0].streak)-day streak for \(habits[0].name)."
        } else {
            content.title = "Streaks at risk"
            content.body = "\(habits.count) habits with active streaks are waiting for you."
        }
        content.sound = .default
        var comps = DateComponents()
        comps.hour = 20
        comps.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        center.add(UNNotificationRequest(identifier: "streak-at-risk", content: content, trigger: trigger))
    }

    func scheduleInactiveUserReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["inactive-user"])
        guard let fireDate = Calendar.current.date(byAdding: .day, value: 5, to: Date()) else { return }
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: fireDate)
        comps.hour = 10
        comps.minute = 0
        let content = UNMutableNotificationContent()
        content.title = "Missing you"
        content.body = "Your habits are waiting. Even one small action keeps the momentum alive."
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        center.add(UNNotificationRequest(identifier: "inactive-user", content: content, trigger: trigger))
    }

    func scheduleMiss2DaysEncouragement() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["miss-2-days"])
        var comps = DateComponents()
        comps.hour = 9
        comps.minute = 0
        let content = UNMutableNotificationContent()
        content.title = "You missed yesterday. That's okay."
        content.body = "Rule: Never miss twice. One small habit today keeps you on track."
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        center.add(UNNotificationRequest(identifier: "miss-2-days", content: content, trigger: trigger))
    }

    // MARK: - Predictive nudge

    /// Schedule a one-off nudge for today at `typicalHour + 2` if that time hasn't passed yet.
    func schedulePredictiveNudge(for habit: Habit, typicalHour: Int) {
        let identifier = "predictive_nudge_\(habit.id.uuidString)"
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let nudgeHour = typicalHour + 2
        guard nudgeHour <= 22 else { return } // don't nudge after 10 PM

        let currentHour = Calendar.current.component(.hour, from: Date())
        guard currentHour < nudgeHour else { return } // nudge time already passed today

        let content = UNMutableNotificationContent()
        content.title = "\(habit.emoji) \(habit.name)"
        content.body = "You usually do this around \(formatHour(typicalHour)). Don't break the chain!"
        content.sound = .default

        var comps = DateComponents()
        comps.hour = nudgeHour
        comps.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }

    func cancelPredictiveNudge(for habitId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["predictive_nudge_\(habitId.uuidString)"]
        )
    }

    private func formatHour(_ hour: Int) -> String {
        switch hour {
        case 0: return "midnight"
        case 12: return "noon"
        case 1..<12: return "\(hour) AM"
        default: return "\(hour - 12) PM"
        }
    }

    func uploadDeviceToken(_ token: Data) async {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        guard let userId = try? await supabase.auth.session.user.id else { return }
        _ = try? await supabase
            .from("device_tokens")
            .upsert(["user_id": userId.uuidString, "token": tokenString, "platform": "ios"])
            .execute()
    }
}
