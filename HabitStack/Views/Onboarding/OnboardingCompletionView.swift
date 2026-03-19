//
//  OnboardingCompletionView.swift
//  Better You
//
//  Created by Symphony
//  Phase 2: Issue #20 (Screen 5)
//

import SwiftUI
import PostHog

/// Onboarding Screen 5: "You're Ready"
struct OnboardingCompletionView: View {
    let adoptedHabits: [HabitTemplate]
    let onComplete: () -> Void
    @State private var showPaywall = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Your first 3 habits:")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                ForEach(adoptedHabits.prefix(3)) { habit in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                        
                        HStack(spacing: 4) {
                            Text(habit.emoji)
                            Text(habit.name)
                                .font(.body)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
            
            VStack(spacing: 12) {
                Text("Start tomorrow. Track daily.")
                    .font(.body)
                
                Text("Small wins compound.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Consistency > Perfection")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(.accentColor)
                    .padding(.top, 8)
            }
            .multilineTextAlignment(.center)
            
            Spacer()

            VStack(spacing: 12) {
                Button {
                    PostHogSDK.shared.capture("paywall_shown", properties: ["trigger": "onboarding_completion"])
                    showPaywall = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(.yellow)
                        Text("Start your journey with Pro")
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundColor(.accentColor)
                    .cornerRadius(12)
                }

                Button(action: onComplete) {
                    HStack {
                        Text("Let's go!")
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .controlSize(.large)
            }
        }
        .padding()
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }
}

#Preview {
    OnboardingCompletionView(
        adoptedHabits: [
            HabitTemplate(
                name: "Morning Walk",
                emoji: "🏃",
                description: "",
                suggestedDuration: 15,
                category: .health,
                identityTraits: [],
                defaultTime: .morning
            ),
            HabitTemplate(
                name: "Read 10 Pages",
                emoji: "📖",
                description: "",
                suggestedDuration: 15,
                category: .learning,
                identityTraits: [],
                defaultTime: .evening
            ),
            HabitTemplate(
                name: "Meditation",
                emoji: "🧘",
                description: "",
                suggestedDuration: 10,
                category: .mindfulness,
                identityTraits: [],
                defaultTime: .morning
            )
        ],
        onComplete: {}
    )
}
