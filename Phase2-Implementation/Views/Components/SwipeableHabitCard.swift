//
//  SwipeableHabitCard.swift
//  Better You
//
//  Created by Symphony
//  Phase 2: Issue #21
//

import SwiftUI

/// Tinder-style swipeable card for habit adoption
struct SwipeableHabitCard: View {
    let template: HabitTemplate
    @State private var offset: CGSize = .zero
    @State private var isDragging = false
    
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void
    
    var body: some View {
        ZStack {
            // Card background
            cardBackground
            
            VStack(spacing: 20) {
                Text(template.emoji)
                    .font(.system(size: 60))
                
                VStack(spacing: 8) {
                    Text(template.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("\(template.suggestedDuration) minutes · \(template.category.displayName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text(template.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                HStack(spacing: 50) {
                    Label("Skip", systemImage: "xmark")
                        .foregroundColor(.red)
                        .font(.callout)
                    Label("Adopt", systemImage: "checkmark")
                        .foregroundColor(.green)
                        .font(.callout)
                }
            }
            .padding(30)
        }
        .frame(width: 320, height: 450)
        .offset(offset)
        .rotationEffect(.degrees(Double(offset.width / 20)))
        .gesture(dragGesture)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(cardColor)
            .shadow(
                color: .black.opacity(isDragging ? 0.3 : 0.2),
                radius: isDragging ? 12 : 8
            )
    }
    
    private var cardColor: LinearGradient {
        if offset.width > 50 {
            return LinearGradient(
                colors: [Color.green.opacity(0.3), .white],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else if offset.width < -50 {
            return LinearGradient(
                colors: [Color.red.opacity(0.3), .white],
                startPoint: .trailing,
                endPoint: .leading
            )
        } else {
            return LinearGradient(
                colors: [.white],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { gesture in
                isDragging = true
                offset = gesture.translation
            }
            .onEnded { gesture in
                isDragging = false
                
                // Threshold for completing swipe
                if abs(offset.width) > 100 {
                    completeSwipe(offset.width > 0 ? .right : .left)
                } else {
                    // Snap back
                    withAnimation(.spring(response: 0.3)) {
                        offset = .zero
                    }
                }
            }
    }
    
    private func completeSwipe(_ direction: SwipeDirection) {
        withAnimation(.easeOut(duration: 0.3)) {
            offset = CGSize(
                width: direction == .right ? 500 : -500,
                height: 0
            )
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if direction == .right {
                onSwipeRight()
            } else {
                onSwipeLeft()
            }
            offset = .zero
        }
    }
}

enum SwipeDirection {
    case left, right
}

#Preview {
    SwipeableHabitCard(
        template: HabitTemplate(
            name: "Morning Walk",
            emoji: "🏃",
            description: "Start your day strong",
            suggestedDuration: 15,
            category: .health,
            identityTraits: [.stronger, .energetic],
            defaultTime: .morning
        ),
        onSwipeLeft: { print("Skipped") },
        onSwipeRight: { print("Adopted") }
    )
}
