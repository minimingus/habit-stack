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

    func uploadDeviceToken(_ token: Data) async {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        guard let userId = try? await supabase.auth.session.user.id else { return }
        try? await supabase
            .from("device_tokens")
            .upsert(["user_id": userId.uuidString, "token": tokenString, "platform": "ios"])
            .execute()
    }
}
