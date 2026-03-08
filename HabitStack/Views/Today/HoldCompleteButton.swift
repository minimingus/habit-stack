import SwiftUI
import AudioToolbox

/// Press-and-hold to complete. Hold for ~0.6s to fill the ring and complete.
/// Single tap on a completed habit uncompletes it.
struct HoldCompleteButton: View {
    let isCompleted: Bool
    let accentColor: Color
    let onComplete: () -> Void
    let onUncomplete: () -> Void

    @State private var progress: Double = 0
    @State private var isPressed = false
    @State private var timer: Timer?
    @State private var resetTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            // Base fill
            Circle()
                .fill(isCompleted ? accentColor : Color("Stone100"))
                .frame(width: 56, height: 56)

            // Border ring
            Circle()
                .strokeBorder(accentColor.opacity(isCompleted ? 0 : 0.35), lineWidth: 2)
                .frame(width: 56, height: 56)

            // Hold progress ring (only shown while pressing, not when completed)
            if !isCompleted {
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 56, height: 56)
                    .animation(.linear(duration: 0.02), value: progress)
            }

            // Checkmark
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
                    if isCompleted {
                        // For completed habits, just track press for scale feedback
                        if !isPressed { isPressed = true }
                        return
                    }
                    if !isPressed {
                        isPressed = true
                        HapticManager.impact(.light)
                        startHoldTimer()
                    }
                }
                .onEnded { _ in
                    if isCompleted {
                        isPressed = false
                        HapticManager.impact(.medium)
                        onUncomplete()
                        return
                    }
                    isPressed = false
                    if progress >= 1.0 { return } // already fired via timer
                    cancelHoldTimer()
                    withAnimation(.spring(duration: 0.3)) { progress = 0 }
                }
        )
    }

    private func startHoldTimer() {
        resetTask?.cancel()
        resetTask = nil
        timer?.invalidate()
        let interval = 0.02
        let step = interval / 0.6
        let t = Timer(timeInterval: interval, repeats: true) { _ in
            Task { @MainActor in
                progress = min(1.0, progress + step)
                if progress >= 1.0 {
                    timer?.invalidate()
                    timer = nil
                    isPressed = false
                    HapticManager.impact(.medium)
                    AudioServicesPlaySystemSound(1104)
                    onComplete()
                    scheduleProgressReset()
                }
            }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func scheduleProgressReset() {
        resetTask?.cancel()
        resetTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.spring(duration: 0.3)) { progress = 0 }
        }
    }

    private func cancelHoldTimer() {
        timer?.invalidate()
        timer = nil
    }
}
