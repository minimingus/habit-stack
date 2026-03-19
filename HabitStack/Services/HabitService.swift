import Foundation
import Supabase
import PostHog

enum HabitServiceError: Error {
    case freeTierHabitLimit
    case freeTierHistoryLimit
}

final class HabitService {
    static let shared = HabitService()
    private init() {}

    private let freeTierHabitLimit = 5
    private let freeTierHistoryDays = 7
    private static let iso8601 = ISO8601DateFormatter()

    func fetchTodayHabits(userId: UUID) async throws -> [HabitWithStatus] {
        // Fetch all non-archived habits; TodayViewModel splits active vs paused
        let habits: [Habit] = try await supabase
            .from("habits")
            .select()
            .eq("user_id", value: userId.uuidString)
            .is("archived_at", value: nil)
            .order("sort_order")
            .execute()
            .value

        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let logs: [HabitLog] = try await supabase
            .from("habit_logs")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("logged_at", value: ISO8601DateFormatter().string(from: today))
            .lt("logged_at", value: ISO8601DateFormatter().string(from: tomorrow))
            .execute()
            .value

        let logsByHabit = Dictionary(grouping: logs, by: { $0.habitId })

        return habits.map { habit in
            let log = logsByHabit[habit.id]?.first
            return HabitWithStatus(
                habit: habit,
                isCompleted: log?.status == .done,
                log: log
            )
        }
    }

    func createHabit(_ habit: Habit, isPro: Bool) async throws {
        if !isPro {
            let existing: [Habit] = try await supabase
                .from("habits")
                .select()
                .eq("user_id", value: habit.userId.uuidString)
                .is("archived_at", value: nil)
                .execute()
                .value
            if existing.count >= freeTierHabitLimit {
                throw HabitServiceError.freeTierHabitLimit
            }
        }
        try await supabase.from("habits").insert(habit).execute()
        PostHogSDK.shared.capture("habit_created", properties: [
            "habit_name": habit.name,
            "time_of_day": habit.timeOfDay.rawValue
        ])
        NotificationManager.shared.scheduleReminder(for: habit)
    }

    func updateHabit(_ habit: Habit) async throws {
        try await supabase
            .from("habits")
            .update(habit)
            .eq("id", value: habit.id.uuidString)
            .execute()
        NotificationManager.shared.cancelReminder(for: habit.id)
        NotificationManager.shared.scheduleReminder(for: habit)
    }

    func archiveHabit(_ habitId: UUID) async throws {
        try await supabase
            .from("habits")
            .update(["archived_at": Self.iso8601.string(from: Date())])
            .eq("id", value: habitId.uuidString)
            .execute()
        NotificationManager.shared.cancelReminder(for: habitId)
    }

    func fetchArchivedHabits(userId: UUID) async throws -> [Habit] {
        return try await supabase
            .from("habits")
            .select()
            .eq("user_id", value: userId.uuidString)
            .not("archived_at", operator: .is, value: "null")
            .order("archived_at", ascending: false)
            .execute()
            .value
    }

    func restoreHabit(_ habitId: UUID) async throws {
        try await supabase
            .from("habits")
            .update(["archived_at": nil as String?])
            .eq("id", value: habitId.uuidString)
            .execute()
    }

    func pauseHabit(_ habitId: UUID, until: Date) async throws {
        try await supabase
            .from("habits")
            .update(["paused_until": Self.iso8601.string(from: until)])
            .eq("id", value: habitId.uuidString)
            .execute()
        NotificationManager.shared.cancelReminder(for: habitId)
    }

    /// Resumes a paused habit and inserts 'skipped' logs for every day in the
    /// pause window so the streak is preserved.
    func resumeHabit(_ habitId: UUID, userId: UUID, pausedUntil: Date) async throws {
        // Clear the pause
        try await supabase
            .from("habits")
            .update(["paused_until": nil as String?])
            .eq("id", value: habitId.uuidString)
            .execute()

        // Insert skipped logs for each missed day to protect the streak.
        // Find last logged date from streaks to know where the gap starts.
        struct StreakRow: Decodable {
            let lastLoggedDate: Date?
            enum CodingKeys: String, CodingKey { case lastLoggedDate = "last_logged_date" }
        }
        let rows: [StreakRow] = (try? await supabase
            .from("streaks")
            .select("last_logged_date")
            .eq("habit_id", value: habitId.uuidString)
            .execute()
            .value) ?? []

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let gapStart: Date
        if let last = rows.first?.lastLoggedDate {
            gapStart = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: last))!
        } else {
            return // no prior streak, nothing to protect
        }

        // Insert a skipped log for each day from gapStart up to (not including) today
        var day = gapStart
        while day < today {
            let log = HabitLog(
                id: UUID(),
                habitId: habitId,
                userId: userId,
                loggedAt: day,
                status: .skipped
            )
            try? await supabase.from("habit_logs").insert(log).execute()
            day = calendar.date(byAdding: .day, value: 1, to: day)!
        }
    }

    func logHabit(habitId: UUID, userId: UUID, status: HabitLog.Status) async throws {
        let log = HabitLog(
            id: UUID(),
            habitId: habitId,
            userId: userId,
            loggedAt: Date(),
            status: status
        )
        try await supabase.from("habit_logs").insert(log).execute()
    }

    func reorderHabits(_ habits: [Habit]) async throws {
        for (index, habit) in habits.enumerated() {
            try await supabase
                .from("habits")
                .update(["sort_order": index])
                .eq("id", value: habit.id.uuidString)
                .execute()
        }
    }

    func fetchHistory(habitId: UUID, userId: UUID, days: Int, isPro: Bool) async throws -> [HabitLog] {
        let clampedDays = isPro ? days : min(days, freeTierHistoryDays)
        if !isPro && days > freeTierHistoryDays {
            throw HabitServiceError.freeTierHistoryLimit
        }
        let since = Calendar.current.date(byAdding: .day, value: -clampedDays, to: Date())!
        return try await supabase
            .from("habit_logs")
            .select()
            .eq("habit_id", value: habitId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .gte("logged_at", value: ISO8601DateFormatter().string(from: since))
            .order("logged_at", ascending: false)
            .execute()
            .value
    }
}
