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

    // How far dragged as a 0–1 progress value
    private var dragProgress: Double { min(abs(Double(offset.width)) / 100, 1) }
    private var isAddingDirection: Bool { offset.width > 0 }

    var body: some View {
        ZStack {
            // ── Card surface ──────────────────────────────────────────
            RoundedRectangle(cornerRadius: 28)
                .fill(Color(UIColor.systemBackground))
                .shadow(
                    color: .black.opacity(isDragging ? 0.16 : 0.08),
                    radius: isDragging ? 24 : 12,
                    y: isDragging ? 8 : 4
                )

            // ── Directional tint (fades in as you drag) ───────────────
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    isAddingDirection
                        ? Color("Teal").opacity(dragProgress * 0.18)
                        : Color.red.opacity(dragProgress * 0.18)
                )

            // ── Content ───────────────────────────────────────────────
            VStack(spacing: 0) {
                // Category chip
                Text(template.category.displayName.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(Color("Teal"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color("TealLight"))
                    .clipShape(Capsule())
                    .padding(.top, 32)

                // Large emoji
                Text(template.emoji)
                    .font(.system(size: 72))
                    .padding(.top, 20)

                // Name
                Text(template.name)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .padding(.top, 14)

                // Duration
                Text("\(template.suggestedDuration) min")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .padding(.top, 4)

                // Description
                Text(template.description)
                    .font(.callout)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 32)
                    .padding(.top, 12)

                Spacer()

                // Swipe hint
                HStack(spacing: 6) {
                    Image(systemName: "arrow.left")
                        .font(.caption2.weight(.semibold))
                    Text("swipe to skip or add")
                        .font(.caption)
                    Image(systemName: "arrow.right")
                        .font(.caption2.weight(.semibold))
                }
                .foregroundStyle(Color.secondary.opacity(0.5))
                .padding(.bottom, 24)
            }

            // ── Drag label overlay ────────────────────────────────────
            if dragProgress > 0.2 {
                VStack {
                    HStack {
                        if !isAddingDirection {
                            dragLabel(text: "Skip", icon: "xmark", color: .red)
                                .padding(20)
                        }
                        Spacer()
                        if isAddingDirection {
                            dragLabel(text: "Add", icon: "checkmark", color: Color("Teal"))
                                .padding(20)
                        }
                    }
                    Spacer()
                }
                .opacity(dragProgress)
            }
        }
        .frame(width: 320, height: 460)
        .offset(offset)
        .rotationEffect(.degrees(Double(offset.width / 22)))
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
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            offset = .zero
                        }
                    }
                }
        )
        .accessibilityLabel("\(template.name), \(template.category.displayName), \(template.suggestedDuration) minutes")
        .accessibilityAction(named: "Add") { onSwipeRight() }
        .accessibilityAction(named: "Skip") { onSwipeLeft() }
    }

    @ViewBuilder
    private func dragLabel(text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
            Text(text)
                .font(.system(size: 15, weight: .bold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(color.opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(color.opacity(0.4), lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
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
    ZStack {
        Color(UIColor.systemGroupedBackground).ignoresSafeArea()
        SwipeableHabitCard(
            template: HabitTemplate(
                name: "Morning Walk",
                emoji: "🚶",
                description: "Start your day with movement and fresh air to boost energy.",
                suggestedDuration: 15,
                category: .health,
                identityTraits: [.stronger, .energetic],
                defaultTime: .morning
            ),
            onSwipeLeft: {},
            onSwipeRight: {}
        )
    }
}
