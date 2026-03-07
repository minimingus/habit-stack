import SwiftUI
import Observation

@Observable
final class OnboardingViewModel {
    enum Step {
        case welcome
        case habitScorecard
        case identityStatement
        case notificationPermission
        case complete
    }

    var step: Step = .welcome
    var identityStatement: String = ""

    func advance() {
        switch step {
        case .welcome: step = .habitScorecard
        case .habitScorecard: step = .identityStatement
        case .identityStatement: step = .notificationPermission
        case .notificationPermission: step = .complete
        case .complete: break
        }
    }

    func skipIdentity() {
        step = .notificationPermission
    }

    func markComplete() {
        if !identityStatement.isEmpty {
            UserDefaults.standard.set(identityStatement, forKey: "onboardingIdentityStatement")
        }
        UserDefaults.standard.set(true, forKey: "onboardingComplete")
    }
}

struct OnboardingContainerView: View {
    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        switch viewModel.step {
        case .welcome:
            WelcomeView(onStart: { viewModel.advance() })
        case .habitScorecard:
            HabitsScorecardView(onContinue: { viewModel.advance() })
        case .identityStatement:
            IdentityStatementView(
                statement: Binding(
                    get: { viewModel.identityStatement },
                    set: { viewModel.identityStatement = $0 }
                ),
                onContinue: { viewModel.advance() },
                onSkip: { viewModel.skipIdentity() }
            )
        case .notificationPermission:
            NotificationPermissionView(onComplete: { viewModel.advance() })
        case .complete:
            ProgressView()
                .task {
                    viewModel.markComplete()
                    _ = try? await supabase.auth.refreshSession()
                }
        }
    }
}
