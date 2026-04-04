//
//  IdentityTraitCard.swift
//  Better You
//
//  Created by Symphony
//  Phase 2: Component for Issue #19
//

import SwiftUI

/// Selectable card for identity trait
struct IdentityTraitCard: View {
    let trait: IdentityTrait
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(trait.emoji)
                    .font(.system(size: 40))
                
                Text(trait.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .background(
                isSelected ?
                    Color.accentColor.opacity(0.2) :
                    Color(.systemGray6)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.accentColor : Color.clear,
                        lineWidth: 2
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack {
        IdentityTraitCard(
            trait: .stronger,
            isSelected: false,
            action: {}
        )
        IdentityTraitCard(
            trait: .focused,
            isSelected: true,
            action: {}
        )
    }
    .padding()
}
