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
            // Card background — drag gesture lives here only so buttons aren't blocked
            RoundedRectangle(cornerRadius: 16)
                .fill(cardColor)
                .shadow(
                    color: .black.opacity(isDragging ? 0.3 : 0.2),
                    radius: isDragging ? 12 : 8
                )
                .gesture(dragGesture)

            VStack(spacing: 20) {
                Image(systemName: template.category.icon)
                    .font(.system(size: 52, weight: .light))
                    .foregroundStyle(Color("Teal"))

                VStack(spacing: 8) {
                    Text(template.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.primary)
                        .multilineTextAlignment(.center)

                    Text("\(template.suggestedDuration) min · \(template.category.displayName)")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                }

                Text(template.description)
                    .font(.body)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()

                HStack(spacing: 50) {
                    Button(action: onSwipeLeft) {
                        Label("Skip", systemImage: "xmark")
                            .foregroundStyle(Color.red)
                            .font(.callout)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Button(action: onSwipeRight) {
                        Label("Add", systemImage: "checkmark")
                            .foregroundStyle(Color("Teal"))
                            .font(.callout)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color("Teal").opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(30)
            .allowsHitTesting(true)
        }
        .frame(width: 320, height: 450)
        .offset(offset)
        .rotationEffect(.degrees(Double(offset.width / 20)))
        .accessibilityLabel("\(template.name), \(template.category.displayName), \(template.suggestedDuration) minutes")
        .accessibilityHint("Swipe right to add, swipe left to skip")
        .accessibilityAction(named: "Add") { onSwipeRight() }
        .accessibilityAction(named: "Skip") { onSwipeLeft() }
    }

    private var cardColor: LinearGradient {
        if offset.width > 50 {
            return LinearGradient(
                colors: [Color("Teal").opacity(0.15), Color(UIColor.systemBackground)],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else if offset.width < -50 {
            return LinearGradient(
                colors: [Color.red.opacity(0.15), Color(UIColor.systemBackground)],
                startPoint: .trailing,
                endPoint: .leading
            )
        } else {
            return LinearGradient(
                colors: [Color(UIColor.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { gesture in
                isDragging = true
                offset = gesture.translation
            }
            .onEnded { gesture in
                isDragging = false
                if abs(offset.width) > 100 {
                    completeSwipe(offset.width > 0 ? .right : .left)
                } else {
                    withAnimation(.spring(response: 0.3)) {
                        offset = .zero
                    }
                }
            }
    }

    private func completeSwipe(_ direction: SwipeDirection) {
        withAnimation(.easeOut(duration: 0.3)) {
            offset = CGSize(width: direction == .right ? 500 : -500, height: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if direction == .right { onSwipeRight() } else { onSwipeLeft() }
            offset = .zero
        }
    }
}

enum SwipeDirection { case left, right }

#Preview {
    SwipeableHabitCard(
        template: HabitTemplate(
            name: "Morning Walk",
            emoji: "🏃",
            description: "Start your day with movement",
            suggestedDuration: 15,
            category: .health,
            identityTraits: [.stronger, .energetic],
            defaultTime: .morning
        ),
        onSwipeLeft: {},
        onSwipeRight: {}
    )
}
