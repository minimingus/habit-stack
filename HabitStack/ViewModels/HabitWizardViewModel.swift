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
    var timeOfDay: Habit.TimeOfDay = .allDay
    var reminderEnabled: Bool = false
    var reminderTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()

    var currentStep: WizardStep = .cue
    var existingHabits: [Habit] = []
    var isEditing: Bool = false
    var editingHabitId: UUID?
    var isSaving: Bool = false
    var errorMessage: String?
    var suggestedCues: [String] = []

    var isPro: Bool = false

    func prefill(from template: HabitTemplate) {
        name = template.name
        emoji = template.emoji
        tinyVersion = template.tinyVersion
        craving = template.craving
        routine = template.routine
        reward = template.reward
        timeOfDay = template.timeOfDay
        suggestedCues = Self.cues(for: template.dimension)
        cue = suggestedCues.first ?? ""
    }

    static func cues(for dimension: ScorecardResult.Dimension) -> [String] {
        switch dimension {
        case .sleep:
            return ["After I turn off the TV", "After I brush my teeth", "When I get into bed", "After dinner is done"]
        case .movement:
            return ["After I wake up", "After I finish work", "After my morning coffee", "After I change clothes"]
        case .mind:
            return ["After I make my morning coffee", "After I sit at my desk", "After I wake up", "After lunch"]
        case .growth:
            return ["After I get into bed", "After my morning coffee", "After dinner", "After I sit on the couch"]
        }
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
        isPro = await RevenueCatManager.shared.isProUser
    }

    func save(userId: UUID) async throws {
        let habit = Habit(
            id: editingHabitId ?? UUID(),
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
    }
}
