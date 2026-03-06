import SwiftUI
import Observation

@Observable
final class ScorecardViewModel {
    enum Step {
        case welcome
        case scorecardGate
        case questions(index: Int)
        case result(ScorecardResult)
        case habitWizard(HabitTemplate)
        case notificationPermission
        case complete
    }

    var step: Step = .welcome
    var answers: [ScorecardResult.Dimension: Int] = [:]
    var isLoading = false

    var dimensions: [ScorecardResult.Dimension] = ScorecardResult.Dimension.allCases

    func advance() {
        switch step {
        case .welcome:
            step = .scorecardGate
        case .scorecardGate:
            step = .questions(index: 0)
        case .questions(let index):
            if index < dimensions.count - 1 {
                step = .questions(index: index + 1)
            } else {
                computeResult()
            }
        case .result(let result):
            let template = ScorecardService.templateHabit(for: result.recommended)
            step = .habitWizard(template)
        case .habitWizard:
            step = .notificationPermission
        case .notificationPermission:
            step = .complete
        case .complete:
            break
        }
    }

    func skipToHabitWizard() {
        let result = ScorecardService.calculate(sleep: 3, movement: 3, mind: 3, growth: 3)
        step = .habitWizard(ScorecardService.templateHabit(for: result.recommended))
    }

    func answer(_ score: Int, for dimension: ScorecardResult.Dimension) {
        answers[dimension] = score
        advance()
    }

    private func computeResult() {
        let result = ScorecardService.calculate(
            sleep: answers[.sleep] ?? 3,
            movement: answers[.movement] ?? 3,
            mind: answers[.mind] ?? 3,
            growth: answers[.growth] ?? 3
        )
        step = .result(result)
        Task { await saveResult(result) }
    }

    private func saveResult(_ result: ScorecardResult) async {
        guard let userId = try? await supabase.auth.session.user.id else { return }
        struct Payload: Encodable {
            let scorecardResult: ScorecardResult
            enum CodingKeys: String, CodingKey { case scorecardResult = "scorecard_result" }
        }
        try? await supabase
            .from("profiles")
            .update(Payload(scorecardResult: result))
            .eq("id", value: userId.uuidString)
            .execute()
    }

    func markOnboardingComplete() async {
        // scorecard_result being set marks onboarding complete
        // RootViewModel will react to profile change
    }
}

struct OnboardingContainerView: View {
    @State private var viewModel = ScorecardViewModel()
    @State private var showHabitWizard = false
    @State private var wizardTemplate: HabitTemplate?

    var body: some View {
        switch viewModel.step {
        case .welcome:
            WelcomeView(onStart: { viewModel.advance() })
        case .scorecardGate:
            ScorecardGateView(
                onTakeScorecard: { viewModel.advance() },
                onSkip: { viewModel.skipToHabitWizard() }
            )
        case .questions(let index):
            ScorecardQuestionView(
                dimension: viewModel.dimensions[index],
                questionIndex: index,
                total: viewModel.dimensions.count,
                onAnswer: { score in viewModel.answer(score, for: viewModel.dimensions[index]) },
                onSkip: { viewModel.skipToHabitWizard() }
            )
        case .result(let result):
            ScorecardResultView(result: result, onContinue: { viewModel.advance() })
        case .habitWizard(let template):
            HabitWizardView(prefillTemplate: template, onSave: { viewModel.advance() })
        case .notificationPermission:
            NotificationPermissionView(onComplete: { viewModel.advance() })
        case .complete:
            // Trigger RootViewModel reload
            ProgressView()
                .task {
                    // Force auth state refresh so RootViewModel re-checks onboarding
                    _ = try? await supabase.auth.session
                }
        }
    }
}
