//
//  OnboardingIdentitySelectionView.swift
//  Better You
//
//  Created by Symphony
//  Phase 2: Issue #19
//

import SwiftUI

/// Onboarding Screen 2: "Choose Your Future Self"
struct OnboardingIdentitySelectionView: View {
    @Binding var selectedTraits: Set<IdentityTrait>
    let onContinue: () -> Void
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Who do you want to become?")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Select all that resonate")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top)
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(IdentityTrait.allCases) { trait in
                        IdentityTraitCard(
                            trait: trait,
                            isSelected: selectedTraits.contains(trait)
                        ) {
                            toggleSelection(trait)
                        }
                    }
                }
            }
            
            Button(action: onContinue) {
                Text("Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedTraits.isEmpty ? Color.gray : Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(selectedTraits.isEmpty)
        }
        .padding()
    }
    
    private func toggleSelection(_ trait: IdentityTrait) {
        withAnimation(.spring(response: 0.3)) {
            if selectedTraits.contains(trait) {
                selectedTraits.remove(trait)
            } else {
                selectedTraits.insert(trait)
            }
        }
    }
}

#Preview {
    OnboardingIdentitySelectionView(
        selectedTraits: .constant([.stronger, .focused]),
        onContinue: {}
    )
}
