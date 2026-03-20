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
    @State private var day1ReminderTime: Date?
    @State private var showHabitCreationError = false
    @State private var habitCreationErrorMessage = ""

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
        .alert("Couldn't Save Habits", isPresented: $showHabitCreationError) {
            Button("Retry") {
                Task { await completeOnboarding() }
            }
            Button("Continue Anyway", role: .cancel) {
                finishOnboarding()
            }
        } message: {
            Text(habitCreationErrorMessage)
        }
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
                state.navigate(to: .notifications)
            }

        case .notifications:
            NotificationPermissionView {
                state.navigate(to: .completion)
            }

        case .completion:
            OnboardingCompletionView(
                adoptedHabits: state.adoptedHabits,
                day1ReminderTime: day1ReminderTime
            ) {
                Task { await completeOnboarding() }
            }
        }
    }

    @MainActor
    private func completeOnboarding() async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            let userId = try await supabase.auth.session.user.id

            var failedCount = 0
            let totalCount = state.adoptedHabits.count

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
                do {
                    try await HabitService.shared.createHabit(habit, isPro: false)
                } catch {
                    failedCount += 1
                    PostHogSDK.shared.capture("onboarding_habit_creation_failed", properties: [
                        "habit_name": template.name,
                        "error": error.localizedDescription
                    ])
                }
            }

            if failedCount == totalCount && totalCount > 0 {
                // All habits failed — show retry prompt
                habitCreationErrorMessage = "Your habits couldn't be saved. Check your connection and try again."
                showHabitCreationError = true
                return
            } else if failedCount > 0 {
                // Some habits failed — show toast-style alert but continue
                habitCreationErrorMessage = "Some habits couldn't be saved. Tap + to add them later."
                showHabitCreationError = true
                return
            }
        } catch {
            // Auth/session error — all habits failed
            PostHogSDK.shared.capture("onboarding_habit_creation_failed", properties: [
                "error": error.localizedDescription,
                "stage": "auth"
            ])
            habitCreationErrorMessage = "Couldn't connect to save your habits. Check your connection and try again."
            showHabitCreationError = true
            return
        }

        finishOnboarding()
    }

    @MainActor
    private func finishOnboarding() {
        PostHogSDK.shared.capture("onboarding_completed", properties: [
            "habits_adopted_count": state.adoptedHabits.count,
            "traits_selected": Array(state.selectedTraits).map(\.rawValue)
        ])

        // Persist selected identity traits for coach context
        let traitStrings = Array(state.selectedTraits).map(\.rawValue)
        UserDefaults.standard.set(traitStrings, forKey: "selectedIdentityTraits")

        // Schedule Day 1 activation notification
        if let firstHabit = state.adoptedHabits.first {
            let scheduledTime = NotificationManager.shared.scheduleDay1Activation(
                firstHabitName: firstHabit.name
            )
            if let scheduledTime {
                PostHogSDK.shared.capture("day1_notification_scheduled", properties: [
                    "scheduled_time": ISO8601DateFormatter().string(from: scheduledTime)
                ])
                day1ReminderTime = scheduledTime
            }
        }

        // Mark onboarding complete and trigger RootView to show main app
        UserDefaults.standard.set(true, forKey: "onboardingComplete")
        Task { _ = try? await supabase.auth.refreshSession() }
    }
}

#Preview {
    OnboardingFlow()
}
