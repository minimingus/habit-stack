import SwiftUI
import Observation

@Observable
final class OnboardingViewModel {
    enum Step {
        case welcome
        case habitScorecard
        case notificationPermission
        case complete
    }

    var step: Step = .welcome

    func advance() {
        switch step {
        case .welcome: step = .habitScorecard
        case .habitScorecard: step = .notificationPermission
        case .notificationPermission: step = .complete
        case .complete: break
        }
    }

    func markComplete() {
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
            ScorecardOnboardingView(onContinue: { viewModel.advance() })
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
