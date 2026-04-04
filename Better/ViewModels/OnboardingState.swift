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
@Observable
class OnboardingState {
    var path: [OnboardingStep] = []
    var selectedTraits: Set<IdentityTrait> = []
    var adoptedHabits: [HabitTemplate] = []

    /// Navigate to specific step
    func navigate(to step: OnboardingStep) {
        path.append(step)
    }
}

/// Onboarding flow steps
enum OnboardingStep: Hashable {
    case vision
    case identity
    case philosophy
    case habitSwipe
    case notifications
    case completion
}
