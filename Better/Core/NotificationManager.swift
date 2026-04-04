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

        if let identity = habit.craving, !identity.isEmpty {
            content.title = "Time to vote for \(identity.capitalized)"
            content.body = "\(habit.emoji) \(habit.name) is waiting."
        } else {
            content.title = "\(habit.emoji) \(habit.name)"
            if let streak, streak.currentStreak > 0 {
                content.body = "Keep your \(streak.currentStreak)-day streak alive."
            } else if let tiny = habit.tinyVersion, !tiny.isEmpty {
                content.body = "Takes just 2 minutes: \(tiny)"
            } else {
                content.body = "One more vote for who you are becoming."
            }
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
        content.title = "Identity votes remaining"
        content.body = "You have \(pendingCount) identity vote\(pendingCount == 1 ? "" : "s") left today."
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
            content.title = "Your identity streak is at risk"
            content.body = "\(habits[0].streak) days of proof. 2 minutes keeps the vote alive."
        } else {
            content.title = "\(habits.count) identity votes at risk"
            content.body = "Each one is proof of who you are becoming."
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
        content.title = "Your identity is fading"
        content.body = "One action brings it back. Vote for who you are becoming."
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
        content.title = "Missing a day doesn't change who you are"
        content.body = "One vote today keeps your identity alive."
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
        if let identity = habit.craving, !identity.isEmpty {
            content.title = "Vote for \(identity.capitalized)"
            content.body = "You usually cast this vote around \(formatHour(typicalHour))."
        } else {
            content.title = "\(habit.emoji) \(habit.name)"
            content.body = "You usually do this around \(formatHour(typicalHour))."
        }
        content.sound = .default

        var comps = DateComponents()
        comps.hour = nudgeHour
        comps.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }

    // MARK: - Day 1 activation

    /// Schedule a one-time notification for the user's first day after onboarding.
    /// Fires at the first habit's reminder time tomorrow, or 8 AM if none set.
    /// Returns the scheduled time for UI display, or nil if scheduling failed.
    @discardableResult
    func scheduleDay1Activation(firstHabitName: String, reminderTime: Date? = nil) -> Date? {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["day1-activation"])

        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) else { return nil }

        var fireComponents = calendar.dateComponents([.year, .month, .day], from: tomorrow)
        if let reminderTime {
            let timeComps = calendar.dateComponents([.hour, .minute], from: reminderTime)
            fireComponents.hour = timeComps.hour
            fireComponents.minute = timeComps.minute
        } else {
            fireComponents.hour = 8
            fireComponents.minute = 0
        }

        let content = UNMutableNotificationContent()
        content.title = "Your first day starts now"
        content.body = "Time to check off \(firstHabitName). You've got this."
        content.sound = .default
        content.userInfo = ["type": "day1_activation"]

        let trigger = UNCalendarNotificationTrigger(dateMatching: fireComponents, repeats: false)
        center.add(UNNotificationRequest(identifier: "day1-activation", content: content, trigger: trigger))

        return calendar.date(from: fireComponents)
    }

    // MARK: - Extra reminders

    func scheduleExtraReminders(for habit: Habit, times: [Date], streak: Streak? = nil) {
        cancelExtraReminders(for: habit.id)
        for (index, time) in times.prefix(2).enumerated() {
            let content = UNMutableNotificationContent()
            if let identity = habit.craving, !identity.isEmpty {
                content.title = "Vote for \(identity.capitalized)"
                content.body = "\(habit.emoji) \(habit.name) is waiting."
            } else {
                content.title = "\(habit.emoji) \(habit.name)"
                if let streak, streak.currentStreak > 0 {
                    content.body = "Keep your \(streak.currentStreak)-day streak alive."
                } else if let tiny = habit.tinyVersion, !tiny.isEmpty {
                    content.body = "Takes just 2 minutes: \(tiny)"
                } else {
                    content.body = "One more vote for who you are becoming."
                }
            }
            content.sound = .default
            var components = Calendar.current.dateComponents([.hour, .minute], from: time)
            components.second = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(
                identifier: "extra_reminder_\(habit.id.uuidString)_\(index)",
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request)
        }
    }

    func cancelExtraReminders(for habitId: UUID) {
        let identifiers = (0..<2).map { "extra_reminder_\(habitId.uuidString)_\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    // MARK: - Trial expiry nudge

    func scheduleTrialExpiryNotifications(expirationDate: Date) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [
            "trial-expiry-24h", "trial-expiry-day"
        ])

        let calendar = Calendar.current

        // 24h before expiry
        if let dayBefore = calendar.date(byAdding: .day, value: -1, to: expirationDate),
           dayBefore > Date() {
            var comps = calendar.dateComponents([.year, .month, .day], from: dayBefore)
            comps.hour = 10
            comps.minute = 0
            let content = UNMutableNotificationContent()
            content.title = "Your Pro trial ends tomorrow"
            content.body = "Keep unlimited habits and your AI coach — upgrade now."
            content.sound = .default
            content.userInfo = ["type": "trial_expiry_24h"]
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            center.add(UNNotificationRequest(identifier: "trial-expiry-24h", content: content, trigger: trigger))
        }

        // On expiry day
        let expiryDay = calendar.startOfDay(for: expirationDate)
        if expiryDay >= calendar.startOfDay(for: Date()) {
            var comps = calendar.dateComponents([.year, .month, .day], from: expiryDay)
            comps.hour = 10
            comps.minute = 0
            let content = UNMutableNotificationContent()
            content.title = "Your Pro trial ended"
            content.body = "Your habits are safe — upgrade to keep unlimited access."
            content.sound = .default
            content.userInfo = ["type": "trial_expiry_day"]
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            center.add(UNNotificationRequest(identifier: "trial-expiry-day", content: content, trigger: trigger))
        }
    }

    func cancelTrialExpiryNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["trial-expiry-24h", "trial-expiry-day"]
        )
    }

    // MARK: - Monthly recap push

    func scheduleMonthlyRecapPush() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["monthly-recap"])

        let calendar = Calendar.current
        let now = Date()

        // Schedule for 9 AM on the 1st of next month
        guard let firstOfThisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let firstOfNextMonth = calendar.date(byAdding: .month, value: 1, to: firstOfThisMonth) else { return }

        var comps = calendar.dateComponents([.year, .month, .day], from: firstOfNextMonth)
        comps.hour = 9
        comps.minute = 0

        let monthName = calendar.monthSymbols[(calendar.component(.month, from: now)) - 1]

        let content = UNMutableNotificationContent()
        content.title = "Your \(monthName) recap is ready"
        content.body = "See how your habits shaped who you are becoming."
        content.sound = .default
        content.userInfo = ["type": "monthly_recap"]

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        center.add(UNNotificationRequest(identifier: "monthly-recap", content: content, trigger: trigger))
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
