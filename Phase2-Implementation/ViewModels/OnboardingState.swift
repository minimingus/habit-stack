//
//  OnboardingState.swift
//  Better You
//
//  Created by Symphony
//  Phase 2: Issue #22
//

import Foundation
import SwiftUI

/// State management for onboarding flow
class OnboardingState: ObservableObject {
    @Published var path: [OnboardingStep] = []
    @Published var selectedTraits: Set<IdentityTrait> = []
    @Published var adoptedHabits: [HabitTemplate] = []
    
    /// Navigate to specific step
    func navigate(to step: OnboardingStep) {
        path.append(step)
    }
    
    /// Go back one step
    func goBack() {
        path.removeLast()
    }
    
    /// Complete onboarding and save data
    func complete() {
        // TODO: Save futureSelf to profile
        // TODO: Save adoptedHabits to database
        // TODO: Mark onboarding as complete
        // TODO: Navigate to main app
    }
}

/// Onboarding flow steps
enum OnboardingStep: Hashable {
    case vision
    case identity
    case philosophy
    case habitSwipe
    case completion
}
