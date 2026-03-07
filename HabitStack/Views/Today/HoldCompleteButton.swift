import SwiftUI

/// Atoms-style hold-to-complete circle. Hold for ~0.75s to log a habit.
struct HoldCompleteButton: View {
    let isCompleted: Bool
    let accentColor: Color
    let onComplete: () -> Void
    let onUncomplete: () -> Void

    @State private var progress: Double = 0

    var body: some View {
        ZStack {
            // Background fill
            Circle()
                .fill(isCompleted ? accentColor : Color("Stone100"))
                .frame(width: 56, height: 56)

            // Progress ring (fills while holding)
            if !isCompleted {
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(accentColor, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))
            }

            // Checkmark (visible when completed)
            Image(systemName: "checkmark")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .opacity(isCompleted ? 1 : 0)
                .scaleEffect(isCompleted ? 1 : 0.5)
                .animation(.spring(duration: 0.3), value: isCompleted)
        }
        .scaleEffect(progress > 0 ? 1.08 : 1.0)
        .animation(.spring(duration: 0.2), value: progress > 0)
        .onLongPressGesture(
            minimumDuration: 0.75,
            perform: {
                HapticManager.impact(.medium)
                withAnimation(.spring(duration: 0.2)) { progress = 0 }
                if isCompleted { onUncomplete() } else { onComplete() }
            },
            onPressingChanged: { pressing in
                if isCompleted {
                    // Single tap to uncomplete — just fire immediately
                    return
                }
                if pressing {
                    HapticManager.impact(.light)
                    withAnimation(.linear(duration: 0.75)) { progress = 1.0 }
                } else {
                    withAnimation(.spring(duration: 0.2)) { progress = 0 }
                }
            }
        )
        // Tap to uncomplete (already completed)
        .simultaneousGesture(
            TapGesture().onEnded {
                if isCompleted {
                    HapticManager.impact(.light)
                    onUncomplete()
                }
            }
        )
    }
}
