import SwiftUI

struct HabitTimerView: View {
    let habitName: String
    let habitEmoji: String
    let durationMinutes: Int
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var secondsRemaining: Int
    @State private var isRunning = false
    @State private var timer: Timer? = nil
    @State private var finished = false

    init(habitName: String, habitEmoji: String, durationMinutes: Int, onComplete: @escaping () -> Void) {
        self.habitName = habitName
        self.habitEmoji = habitEmoji
        self.durationMinutes = durationMinutes
        self.onComplete = onComplete
        _secondsRemaining = State(initialValue: durationMinutes * 60)
    }

    private var progress: Double {
        let total = durationMinutes * 60
        return total == 0 ? 1 : 1 - Double(secondsRemaining) / Double(total)
    }

    private var timeString: String {
        let m = secondsRemaining / 60
        let s = secondsRemaining % 60
        return String(format: "%d:%02d", m, s)
    }

    var body: some View {
        VStack(spacing: 48) {
            Spacer()

            // Habit label
            VStack(spacing: 8) {
                Text(habitEmoji)
                    .font(.system(size: 52))
                Text(habitName)
                    .font(.title3.bold())
                    .foregroundStyle(Color("Stone950"))
            }

            // Timer ring
            ZStack {
                Circle()
                    .stroke(Color("Stone100"), lineWidth: 10)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Color("Teal"),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)

                VStack(spacing: 4) {
                    Text(finished ? "Done!" : timeString)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(finished ? Color("Teal") : Color("Stone950"))
                    if !finished {
                        Text("remaining")
                            .font(.caption)
                            .foregroundStyle(Color("Stone500"))
                    }
                }
            }
            .frame(width: 220, height: 220)

            // Controls
            if finished {
                Button {
                    onComplete()
                    dismiss()
                } label: {
                    Text("Log Completion")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("Teal"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 40)
            } else {
                HStack(spacing: 24) {
                    Button {
                        isRunning ? pauseTimer() : startTimer()
                    } label: {
                        Image(systemName: isRunning ? "pause.fill" : "play.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 64, height: 64)
                            .background(Color("Teal"))
                            .clipShape(Circle())
                    }

                    Button {
                        pauseTimer()
                        secondsRemaining = durationMinutes * 60
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title3)
                            .foregroundStyle(Color("Stone500"))
                            .frame(width: 48, height: 48)
                            .background(Color("Stone100"))
                            .clipShape(Circle())
                    }
                }
            }

            Spacer()

            Button("Cancel") { dismiss() }
                .foregroundStyle(Color("Stone500"))
                .padding(.bottom, 32)
        }
        .background(Color("Stone100").ignoresSafeArea())
        .onAppear { startTimer() }
        .onDisappear { pauseTimer() }
    }

    private func startTimer() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if secondsRemaining > 0 {
                secondsRemaining -= 1
                if secondsRemaining == 0 {
                    finished = true
                    HapticManager.notification(.success)
                    pauseTimer()
                }
            }
        }
    }

    private func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
}
