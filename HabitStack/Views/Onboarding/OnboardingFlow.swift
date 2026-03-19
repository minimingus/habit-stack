//
//  OnboardingFlow.swift
//  Better You
//
//  Created by Symphony
//  Phase 2: Issue #22
//

import SwiftUI
import PostHog

/// Main onboarding coordinator view
struct OnboardingFlow: View {
    @StateObject private var state = OnboardingState()
    @State private var isSaving = false

    var body: some View {
        NavigationStack(path: $state.path) {
            OnboardingVisionView {
                state.navigate(to: .identity)
            }
            .navigationDestination(for: OnboardingStep.self) { step in
                destinationView(for: step)
            }
        }
        .interactiveDismissDisabled()
    }

    @ViewBuilder
    private func destinationView(for step: OnboardingStep) -> some View {
        switch step {
        case .vision:
            OnboardingVisionView {
                state.navigate(to: .identity)
            }

        case .identity:
            OnboardingIdentitySelectionView(
                selectedTraits: $state.selectedTraits
            ) {
                PostHogSDK.shared.capture("onboarding_identity_selected", properties: [
                    "traits": Array(state.selectedTraits).map(\.rawValue)
                ])
                state.navigate(to: .philosophy)
            }

        case .philosophy:
            OnboardingPhilosophyView(
                selectedTraits: Array(state.selectedTraits)
            ) {
                PostHogSDK.shared.capture("onboarding_philosophy_completed")
                state.navigate(to: .habitSwipe)
            }

        case .habitSwipe:
            OnboardingHabitSwipeView(
                selectedTraits: Array(state.selectedTraits),
                adoptedHabits: $state.adoptedHabits
            ) {
                state.navigate(to: .completion)
            }

        case .completion:
            OnboardingCompletionView(
                adoptedHabits: state.adoptedHabits
            ) {
                Task { await completeOnboarding() }
            }
        }
    }

    @MainActor
    private func completeOnboarding() async {
        guard !isSaving else { return }
        isSaving = true

        do {
            let userId = try await supabase.auth.session.user.id

            // Convert each adopted template into a real Habit and persist it
            for (index, template) in state.adoptedHabits.enumerated() {
                let timeOfDay: Habit.TimeOfDay = {
                    switch template.defaultTime {
                    case .morning: return .morning
                    case .afternoon: return .afternoon
                    case .evening: return .evening
                    case .anytime: return .allDay
                    }
                }()

                let habit = Habit(
                    id: UUID(),
                    userId: userId,
                    name: template.name,
                    emoji: template.emoji,
                    color: "#0D9488",
                    frequency: .daily,
                    timeOfDay: timeOfDay,
                    reminderEnabled: false,
                    sortOrder: index,
                    createdAt: Date()
                )
                try await HabitService.shared.createHabit(habit, isPro: false)
            }
        } catch {
            // Non-fatal — habits can be added later; don't block onboarding completion
        }

        PostHogSDK.shared.capture("onboarding_completed", properties: [
            "habits_adopted_count": state.adoptedHabits.count,
            "traits_selected": Array(state.selectedTraits).map(\.rawValue)
        ])

        // Mark onboarding complete and trigger RootView to show main app
        UserDefaults.standard.set(true, forKey: "onboardingComplete")
        _ = try? await supabase.auth.refreshSession()
    }
}

#Preview {
    OnboardingFlow()
}
