import SwiftUI

/// Tap-to-complete circle. Single tap marks done; tap again to undo.
struct HoldCompleteButton: View {
    let isCompleted: Bool
    let accentColor: Color
    let onComplete: () -> Void
    let onUncomplete: () -> Void

    @State private var isPressed = false

    var body: some View {
        ZStack {
            Circle()
                .fill(isCompleted ? accentColor : Color("Stone100"))
                .frame(width: 56, height: 56)

            Circle()
                .strokeBorder(accentColor.opacity(isCompleted ? 0 : 0.35), lineWidth: 2)
                .frame(width: 56, height: 56)

            Image(systemName: "checkmark")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(isCompleted ? .white : accentColor.opacity(0.3))
                .scaleEffect(isCompleted ? 1 : 0.8)
                .animation(.spring(duration: 0.3), value: isCompleted)
        }
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .animation(.spring(duration: 0.15), value: isPressed)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed { isPressed = true; HapticManager.impact(.light) }
                }
                .onEnded { _ in
                    isPressed = false
                    HapticManager.impact(.medium)
                    if isCompleted { onUncomplete() } else { onComplete() }
                }
        )
    }
}
