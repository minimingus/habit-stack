//
//  OnboardingHabitSwipeView.swift
//  Better You
//
//  Created by Symphony
//  Phase 2: Issue #20 (Screen 4)
//

import SwiftUI
import PostHog

/// Onboarding Screen 4: "Swipe to Adopt Habits"
struct OnboardingHabitSwipeView: View {
    let selectedTraits: [IdentityTrait]
    @Binding var adoptedHabits: [HabitTemplate]
    @State private var suggestedHabits: [HabitTemplate] = []
    @State private var currentIndex: Int = 0
    
    let targetCount: Int = 1
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Based on who you want to become,")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Pick at least 1 habit to start:")
                    .font(.headline)
            }
            .padding(.top)
            
            // Card stack
            ZStack {
                if currentIndex < suggestedHabits.count {
                    // Show current + next card for depth
                    ForEach(currentIndex..<min(currentIndex + 2, suggestedHabits.count), id: \.self) { index in
                        let isFront = index == currentIndex
                        SwipeableHabitCard(
                            template: suggestedHabits[index],
                            onSwipeLeft: { skipHabit(at: index) },
                            onSwipeRight: { adoptHabit(at: index) }
                        )
                        .zIndex(isFront ? 1 : 0)
                        .opacity(isFront ? 1.0 : 0.5)
                        .scaleEffect(isFront ? 1.0 : 0.95)
                        .offset(y: isFront ? 0 : 10)
                        .allowsHitTesting(isFront)
                    }
                } else {
                    // All cards swiped
                    VStack(spacing: 16) {
                        Text("No more suggestions")
                            .font(.title3)
                            .foregroundColor(.secondary)

                        if adoptedHabits.count < targetCount {
                            Text("Pick at least 1 habit to get started")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Button(action: {
                                PostHogSDK.shared.capture("onboarding_habits_reshuffled")
                                withAnimation {
                                    currentIndex = 0
                                    loadSuggestedHabits()
                                }
                            }) {
                                Label("Shuffle new suggestions", systemImage: "shuffle")
                                    .font(.headline)
                                    .padding()
                                    .background(Color.accentColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
            }
            .frame(height: 500)
            
            // Progress
            Text("\(adoptedHabits.count)/\(targetCount) habits adopted")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Continue button (appears when enough habits adopted)
            if adoptedHabits.count >= targetCount {
                VStack(spacing: 12) {
                    Button(action: onComplete) {
                        Text("Continue")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }

                    if currentIndex < suggestedHabits.count {
                        Button(action: {
                            PostHogSDK.shared.capture("onboarding_skip_remaining_habits", properties: [
                                "habits_adopted": adoptedHabits.count,
                                "habits_remaining": suggestedHabits.count - currentIndex
                            ])
                            onComplete()
                        }) {
                            Text("I'll add more later")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding()
        .onAppear {
            loadSuggestedHabits()
        }
    }
    
    private func loadSuggestedHabits() {
        suggestedHabits = HabitTemplateLibrary.randomSuggestions(
            for: selectedTraits,
            count: 10
        )
    }
    
    private func skipHabit(at index: Int) {
        PostHogSDK.shared.capture("onboarding_habit_swiped", properties: [
            "habit_name": suggestedHabits[index].name,
            "direction": "skipped"
        ])
        withAnimation {
            currentIndex += 1
        }
    }

    private func adoptHabit(at index: Int) {
        PostHogSDK.shared.capture("onboarding_habit_swiped", properties: [
            "habit_name": suggestedHabits[index].name,
            "direction": "adopted"
        ])
        withAnimation {
            adoptedHabits.append(suggestedHabits[index])
            currentIndex += 1
        }
    }
}

#Preview {
    OnboardingHabitSwipeView(
        selectedTraits: [.stronger, .focused],
        adoptedHabits: .constant([]),
        onComplete: {}
    )
}
