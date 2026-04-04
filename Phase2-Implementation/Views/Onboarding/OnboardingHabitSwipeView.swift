//
//  OnboardingHabitSwipeView.swift
//  Better You
//
//  Created by Symphony
//  Phase 2: Issue #20 (Screen 4)
//

import SwiftUI

/// Onboarding Screen 4: "Swipe to Adopt Habits"
struct OnboardingHabitSwipeView: View {
    let selectedTraits: [IdentityTrait]
    @Binding var adoptedHabits: [HabitTemplate]
    @State private var suggestedHabits: [HabitTemplate] = []
    @State private var currentIndex: Int = 0
    
    let targetCount: Int = 3
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Based on who you want to become,")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Here are 3 habits to start:")
                    .font(.headline)
            }
            .padding(.top)
            
            // Card stack
            ZStack {
                if currentIndex < suggestedHabits.count {
                    // Show current + next card for depth
                    ForEach(currentIndex..<min(currentIndex + 2, suggestedHabits.count), id: \.self) { index in
                        SwipeableHabitCard(
                            template: suggestedHabits[index],
                            onSwipeLeft: { skipHabit(at: index) },
                            onSwipeRight: { adoptHabit(at: index) }
                        )
                        .zIndex(Double(suggestedHabits.count - index))
                        .opacity(index == currentIndex ? 1.0 : 0.5)
                        .scaleEffect(index == currentIndex ? 1.0 : 0.95)
                        .offset(y: index == currentIndex ? 0 : 10)
                    }
                } else {
                    // All cards swiped
                    Text("No more suggestions")
                        .font(.title3)
                        .foregroundColor(.secondary)
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
                Button(action: onComplete) {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
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
        withAnimation {
            currentIndex += 1
        }
    }
    
    private func adoptHabit(at index: Int) {
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
