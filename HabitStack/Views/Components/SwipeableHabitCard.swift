//
//  SwipeableHabitCard.swift
//  Better You
//

import SwiftUI

struct SwipeableHabitCard: View {
    let template: HabitTemplate
    @State private var offset: CGSize = .zero
    @State private var isDragging = false

    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: .black.opacity(isDragging ? 0.18 : 0.10), radius: isDragging ? 16 : 8, y: 4)

            // Swipe hint overlay
            if offset.width > 40 {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color("Teal").opacity(min(Double(offset.width - 40) / 100, 0.15)))
            } else if offset.width < -40 {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.red.opacity(min(Double(-offset.width - 40) / 100, 0.15)))
            }

            VStack(spacing: 0) {
                // Emoji in a tinted squircle
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color("TealLight"))
                        .frame(width: 72, height: 72)
                    Text(template.emoji)
                        .font(.system(size: 36))
                }
                .padding(.top, 32)

                // Name
                Text(template.name)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 16)
                    .padding(.horizontal, 24)

                // Meta
                Text("\(template.suggestedDuration) min · \(template.category.displayName)")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .padding(.top, 4)

                // Description
                Text(template.description)
                    .font(.body)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .padding(.top, 12)
                    .lineLimit(3)

                Spacer()

                // Buttons
                HStack(spacing: 32) {
                    Button(action: onSwipeLeft) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark")
                            Text("Skip")
                        }
                        .font(.callout.weight(.medium))
                        .foregroundStyle(Color.secondary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(UIColor.tertiarySystemBackground))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Button(action: onSwipeRight) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                            Text("Add")
                        }
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color("Teal"))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 28)
            }
        }
        .frame(width: 320, height: 460)
        .offset(offset)
        .rotationEffect(.degrees(Double(offset.width / 22)))
        // minimumDistance: 10 ensures simple taps reach the buttons above
        .gesture(
            DragGesture(minimumDistance: 10)
                .onChanged { g in
                    isDragging = true
                    offset = g.translation
                }
                .onEnded { g in
                    isDragging = false
                    if abs(offset.width) > 110 {
                        completeSwipe(offset.width > 0 ? .right : .left)
                    } else {
                        withAnimation(.spring(response: 0.3)) { offset = .zero }
                    }
                }
        )
        .accessibilityLabel("\(template.name), \(template.category.displayName), \(template.suggestedDuration) minutes")
        .accessibilityAction(named: "Add") { onSwipeRight() }
        .accessibilityAction(named: "Skip") { onSwipeLeft() }
    }

    private func completeSwipe(_ direction: SwipeDirection) {
        withAnimation(.easeOut(duration: 0.25)) {
            offset = CGSize(width: direction == .right ? 520 : -520, height: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            direction == .right ? onSwipeRight() : onSwipeLeft()
            offset = .zero
        }
    }
}

enum SwipeDirection { case left, right }

#Preview {
    SwipeableHabitCard(
        template: HabitTemplate(
            name: "Morning Walk",
            emoji: "🚶",
            description: "Start your day with movement and fresh air",
            suggestedDuration: 15,
            category: .health,
            identityTraits: [.stronger, .energetic],
            defaultTime: .morning
        ),
        onSwipeLeft: {},
        onSwipeRight: {}
    )
}
