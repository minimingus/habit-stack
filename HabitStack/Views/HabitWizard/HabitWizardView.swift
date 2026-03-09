import SwiftUI

struct HabitWizardView: View {
    var template: HabitTemplate? = nil
    var editingHabit: Habit? = nil
    var replacingBehavior: String? = nil
    var editingStreak: Int = 0
    let onSave: () -> Void

    @State private var viewModel = HabitWizardViewModel()
    @State private var showPaywall = false
    @State private var showEnvTip = false
    @State private var envTipText = ""
    @AppStorage("streakSafeHintDismissed") private var streakSafeHintDismissed = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.currentStep {
                case .cue:
                    WizardStepCueView(viewModel: viewModel)
                case .craving:
                    WizardStepCravingView(viewModel: viewModel)
                case .routine:
                    WizardStepRoutineView(viewModel: viewModel)
                case .reward:
                    WizardStepRewardView(viewModel: viewModel)
                }
            }
            .navigationTitle(stepTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if viewModel.isFirstStep {
                        Button("Cancel") { dismiss() }
                    } else {
                        Button("Previous") { viewModel.previousStep() }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isLastStep {
                        Button("Save") { Task { await save() } }
                            .disabled(!viewModel.canSave || viewModel.isSaving)
                    } else {
                        Button("Next") { viewModel.nextStep() }
                            .disabled(!viewModel.canSave && viewModel.currentStep == .cue)
                    }
                }
            }
            // Step indicator + streak-safe hint
            .safeAreaInset(edge: .top) {
                VStack(spacing: 0) {
                    StepIndicator(
                        total: HabitWizardViewModel.WizardStep.allCases.count,
                        current: viewModel.currentStep.rawValue
                    )
                    .padding(.top, 8)

                    if viewModel.isEditing && editingStreak > 0 && !streakSafeHintDismissed {
                        HStack(spacing: 10) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(Color("Teal"))
                            Text("Your \(editingStreak)-day streak is safe — editing never resets it.")
                                .font(.caption)
                                .foregroundStyle(Color("Stone500"))
                            Spacer()
                            Button {
                                withAnimation { streakSafeHintDismissed = true }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.caption.bold())
                                    .foregroundStyle(Color("Stone500"))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color("TealLight").opacity(0.5))
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            }
        }
        .interactiveDismissDisabled(true)
        .task {
            await viewModel.loadExistingHabits()
            if let template {
                viewModel.prefill(from: template)
            }
            if let habit = editingHabit {
                viewModel.prefill(from: habit)
            }
            if let behavior = replacingBehavior {
                viewModel.prefill(replacing: behavior)
            }
        }
        .alert("Couldn't Save Habit", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .sheet(isPresented: $showEnvTip, onDismiss: {
            onSave()
            dismiss()
        }) {
            EnvDesignTipSheet(habitName: viewModel.name, tipText: envTipText)
        }
    }

    private var stepTitle: String {
        switch viewModel.currentStep {
        case .cue: return "Make it Obvious"
        case .craving: return "Make it Attractive"
        case .routine: return "Make it Easy"
        case .reward: return "Make it Satisfying"
        }
    }

    private func save() async {
        guard let userId = try? await supabase.auth.session.user.id else { return }
        viewModel.isSaving = true
        do {
            try await viewModel.save(userId: userId)
            // Schedule extra reminders after successful save
            if viewModel.reminderEnabled, let habitId = viewModel.savedHabitId,
               !viewModel.extraReminderTimes.isEmpty {
                let habits = try? await supabase
                    .from("habits").select().eq("id", value: habitId.uuidString)
                    .limit(1).execute().value as [Habit]
                if let habit = habits?.first {
                    NotificationManager.shared.scheduleExtraReminders(for: habit, times: viewModel.extraReminderTimes)
                }
            }
            await MainActor.run {
                if !viewModel.isEditing {
                    envTipText = environmentTip(name: viewModel.name, cue: viewModel.cue)
                    showEnvTip = true
                } else {
                    onSave()
                    dismiss()
                }
            }
        } catch HabitServiceError.freeTierHabitLimit {
            await MainActor.run { showPaywall = true }
        } catch {
            await MainActor.run { viewModel.errorMessage = error.localizedDescription }
        }
        viewModel.isSaving = false
    }

    private func environmentTip(name: String, cue: String) -> String {
        let c = cue.trimmingCharacters(in: .whitespaces)
        if c.isEmpty {
            return "Place a visual reminder for \"\(name)\" somewhere you'll see it every day — a sticky note, an object on your desk, or a phone wallpaper."
        }
        return "To make \"\(name)\" obvious: put a cue right where \"\(c)\" happens so you can't miss it. Out of sight = out of mind."
    }
}

private struct StepIndicator: View {
    let total: Int
    let current: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i <= current ? Color("Teal") : Color("Stone100"))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 24)
        .animation(.spring, value: current)
    }
}
