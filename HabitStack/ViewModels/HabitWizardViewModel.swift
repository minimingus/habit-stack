import Foundation
import Observation

@Observable
final class HabitWizardViewModel {
    enum WizardStep: Int, CaseIterable {
        case cue = 0, craving, routine, reward
    }

    // Habit fields
    var name: String = ""
    var emoji: String = "✅"
    var color: String = "#0D9488"
    var cue: String = ""
    var craving: String = ""
    var routine: String = ""
    var reward: String = ""
    var tinyVersion: String = ""
    var anchorHabitId: UUID? = nil
    var frequency: Habit.Frequency = .daily
    // Custom frequency: set of weekday ints (1=Sun, 2=Mon … 7=Sat, matching Calendar.weekday)
    var customDays: Set<Int> = [2, 3, 4, 5, 6]   // Mon–Fri default
    var timeOfDay: Habit.TimeOfDay = .allDay
    var reminderEnabled: Bool = false
    var reminderTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    // Up to 2 extra reminders (in addition to the primary reminderTime)
    var extraReminderTimes: [Date] = []
    var durationEnabled: Bool = false
    var durationMinutes: Int = 10
    var isQuantified: Bool = false
    var targetCount: Int = 8

    var currentStep: WizardStep = .cue
    var existingHabits: [Habit] = []
    var isEditing: Bool = false
    var editingHabitId: UUID?
    var isSaving: Bool = false
    var errorMessage: String?
    var savedHabitId: UUID?
    var suggestedCues: [String] = []
    var replacingBehavior: String? = nil

    var isPro: Bool = false

    func prefill(from template: HabitTemplate) {
        name = template.name
        emoji = template.emoji
        tinyVersion = template.tinyVersion
        craving = template.identity
        cue = template.cue
        timeOfDay = template.timeOfDay
        reward = template.reward
    }

    func prefill(replacing behavior: String) {
        replacingBehavior = behavior
        cue = "When I feel like \(behavior)"
    }

    func prefill(stackingAfter behavior: String) {
        cue = "After I \(behavior)"
    }

    func prefill(from habit: Habit) {
        isEditing = true
        editingHabitId = habit.id
        name = habit.name
        emoji = habit.emoji
        color = habit.color
        cue = habit.cue ?? ""
        craving = habit.craving ?? ""
        routine = habit.routine ?? ""
        reward = habit.reward ?? ""
        tinyVersion = habit.tinyVersion ?? ""
        anchorHabitId = habit.anchorHabitId
        frequency = habit.frequency
        timeOfDay = habit.timeOfDay
        reminderEnabled = habit.reminderEnabled
        if let rt = habit.reminderTime { reminderTime = rt }
        if let days = UserDefaults.standard.array(forKey: "customDays_\(habit.id.uuidString)") as? [Int] {
            customDays = Set(days)
        }
        if let extras = UserDefaults.standard.array(forKey: "extraReminders_\(habit.id.uuidString)") as? [Double] {
            extraReminderTimes = extras.map { Date(timeIntervalSince1970: $0) }
        }
        let saved = UserDefaults.standard.integer(forKey: "habitDuration_\(habit.id.uuidString)")
        if saved > 0 { durationEnabled = true; durationMinutes = saved }
        isQuantified = UserDefaults.standard.bool(forKey: "habitQuantified_\(habit.id.uuidString)")
        let savedTarget = UserDefaults.standard.integer(forKey: "habitTargetCount_\(habit.id.uuidString)")
        if savedTarget > 0 { targetCount = savedTarget }
    }

    func nextStep() {
        if let next = WizardStep(rawValue: currentStep.rawValue + 1) {
            currentStep = next
        }
    }

    func previousStep() {
        if let prev = WizardStep(rawValue: currentStep.rawValue - 1) {
            currentStep = prev
        }
    }

    var canGoNext: Bool {
        currentStep != .reward
    }

    var isFirstStep: Bool { currentStep == .cue }
    var isLastStep: Bool { currentStep == .reward }
    var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    func loadExistingHabits() async {
        guard let userId = try? await supabase.auth.session.user.id else { return }
        existingHabits = (try? await supabase
            .from("habits")
            .select()
            .eq("user_id", value: userId.uuidString)
            .is("archived_at", value: nil)
            .execute()
            .value) ?? []
        isPro = RevenueCatManager.shared.isProUser
    }

    func save(userId: UUID) async throws {
        let habitId = editingHabitId ?? UUID()
        savedHabitId = habitId
        let habit = Habit(
            id: habitId,
            userId: userId,
            name: name.trimmingCharacters(in: .whitespaces),
            emoji: emoji,
            color: color,
            cue: cue.isEmpty ? nil : cue,
            craving: craving.isEmpty ? nil : craving,
            routine: routine.isEmpty ? nil : routine,
            reward: reward.isEmpty ? nil : reward,
            tinyVersion: tinyVersion.isEmpty ? nil : tinyVersion,
            anchorHabitId: anchorHabitId,
            frequency: frequency,
            timeOfDay: timeOfDay,
            reminderEnabled: reminderEnabled,
            reminderTime: reminderEnabled ? reminderTime : nil,
            archivedAt: nil,
            sortOrder: 0,
            createdAt: Date()
        )

        if isEditing {
            try await HabitService.shared.updateHabit(habit)
        } else {
            try await HabitService.shared.createHabit(habit, isPro: isPro)
        }

        let durationKey = "habitDuration_\(habit.id.uuidString)"
        if durationEnabled && durationMinutes > 0 {
            UserDefaults.standard.set(durationMinutes, forKey: durationKey)
        } else {
            UserDefaults.standard.removeObject(forKey: durationKey)
        }

        if isQuantified && targetCount > 0 {
            UserDefaults.standard.set(true, forKey: "habitQuantified_\(habit.id.uuidString)")
            UserDefaults.standard.set(targetCount, forKey: "habitTargetCount_\(habit.id.uuidString)")
        } else {
            UserDefaults.standard.removeObject(forKey: "habitQuantified_\(habit.id.uuidString)")
            UserDefaults.standard.removeObject(forKey: "habitTargetCount_\(habit.id.uuidString)")
        }

        if frequency == .custom {
            UserDefaults.standard.set(Array(customDays), forKey: "customDays_\(habit.id.uuidString)")
        } else {
            UserDefaults.standard.removeObject(forKey: "customDays_\(habit.id.uuidString)")
        }

        let extraKey = "extraReminders_\(habit.id.uuidString)"
        if reminderEnabled && !extraReminderTimes.isEmpty {
            UserDefaults.standard.set(extraReminderTimes.map { $0.timeIntervalSince1970 }, forKey: extraKey)
        } else {
            UserDefaults.standard.removeObject(forKey: extraKey)
        }
    }
}
