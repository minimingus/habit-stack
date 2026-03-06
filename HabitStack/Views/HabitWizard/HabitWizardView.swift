import SwiftUI

struct HabitWizardView: View {
    let prefillTemplate: HabitTemplate?
    var editingHabit: Habit? = nil
    let onSave: () -> Void

    @State private var viewModel = HabitWizardViewModel()
    @State private var showPaywall = false
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
            // Step indicator
            .safeAreaInset(edge: .top) {
                StepIndicator(
                    total: HabitWizardViewModel.WizardStep.allCases.count,
                    current: viewModel.currentStep.rawValue
                )
                .padding(.top, 8)
            }
        }
        .interactiveDismissDisabled(true)
        .task {
            await viewModel.loadExistingHabits()
            if let template = prefillTemplate {
                viewModel.prefill(from: template)
            }
            if let habit = editingHabit {
                viewModel.prefill(from: habit)
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
        print("[HabitWizard] save() started")
        guard let userId = try? await supabase.auth.session.user.id else {
            print("[HabitWizard] ERROR: no session — returning early")
            return
        }
        print("[HabitWizard] got userId: \(userId)")
        viewModel.isSaving = true
        do {
            print("[HabitWizard] calling viewModel.save()")
            try await viewModel.save(userId: userId)
            print("[HabitWizard] save() succeeded")
            await MainActor.run {
                onSave()
                dismiss()
            }
        } catch HabitServiceError.freeTierHabitLimit {
            await MainActor.run { showPaywall = true }
        } catch {
            print("[HabitWizard] save() threw: \(error)")
            await MainActor.run { viewModel.errorMessage = error.localizedDescription }
        }
        viewModel.isSaving = false
        print("[HabitWizard] save() finished, isSaving = false")
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
