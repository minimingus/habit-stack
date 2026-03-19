//
//  OnboardingFlow.swift
//  Better You
//
//  Created by Symphony
//  Phase 2: Issue #22
//

import SwiftUI

/// Main onboarding coordinator view
struct OnboardingFlow: View {
    @StateObject private var state = OnboardingState()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack(path: $state.path) {
            // Start with vision screen
            OnboardingVisionView {
                state.navigate(to: .identity)
            }
            .navigationDestination(for: OnboardingStep.self) { step in
                destinationView(for: step)
            }
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
                state.navigate(to: .philosophy)
            }
            
        case .philosophy:
            OnboardingPhilosophyView(
                selectedTraits: Array(state.selectedTraits)
            ) {
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
                completeOnboarding()
            }
        }
    }
    
    private func completeOnboarding() {
        // Save user's future self identity
        let futureSelf = FutureSelf(traits: Array(state.selectedTraits))
        // TODO: Save to profile/database
        
        // Save adopted habits
        // TODO: Create habits from templates
        
        // Mark onboarding complete
        // TODO: Update user defaults or app state
        
        // Navigate to main app
        dismiss()
    }
}

#Preview {
    OnboardingFlow()
}
