//
//  OnboardingPhilosophyView.swift
//  Better You
//
//  Created by Symphony
//  Phase 2: Issue #20 (Screen 3)
//

import SwiftUI

/// Onboarding Screen 3: "The Path Forward"
struct OnboardingPhilosophyView: View {
    let selectedTraits: [IdentityTrait]
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 16) {
                (Text("To become ") +
                 Text(traitsString)
                    .fontWeight(.semibold) +
                 Text(",\nsmall daily actions matter most."))
                    .font(.title2)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 20) {
                Text("Let's build your routine,\none habit at a time.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 12) {
                    PrincipleRow(
                        icon: "chart.bar.fill",
                        text: "Consistency beats intensity"
                    )
                    PrincipleRow(
                        icon: "leaf.fill",
                        text: "Small steps, big changes"
                    )
                }
            }
            
            Spacer()
            
            Button(action: onContinue) {
                Text("Start Building")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("Teal"))
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
    
    private var traitsString: String {
        selectedTraits
            .map { $0.displayName.lowercased() }
            .formatted(.list(type: .and))
    }
}

/// Principle row component
struct PrincipleRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color("Teal"))
                .frame(width: 28)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
        .padding()
        .background(Color("Stone100"))
        .cornerRadius(8)
    }
}

#Preview {
    OnboardingPhilosophyView(
        selectedTraits: [.stronger, .focused, .calmer],
        onContinue: {}
    )
}
