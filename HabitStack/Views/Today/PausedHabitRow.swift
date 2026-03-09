import SwiftUI

struct PausedHabitRow: View {
    let habit: Habit
    let onResume: () -> Void

    private var accentColor: Color { Color(hex: habit.color) }

    private var resumeLabel: String {
        guard let until = habit.pausedUntil else { return "Paused" }
        let calendar = Calendar.current
        if calendar.isDateInToday(until) { return "Resumes today" }
        if calendar.isDateInTomorrow(until) { return "Resumes tomorrow" }
        return "Resumes \(until.formatted(.dateTime.month(.abbreviated).day()))"
    }

    var body: some View {
        HStack(spacing: 14) {
            // Dimmed circle placeholder
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: "pause.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(accentColor.opacity(0.5))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(habit.name)
                    .font(.headline)
                    .foregroundStyle(Color("Stone950").opacity(0.5))
                Text(resumeLabel)
                    .font(.caption)
                    .foregroundStyle(Color("Stone500"))
            }

            Spacer()

            Button(action: onResume) {
                Text("Resume")
                    .font(.caption.bold())
                    .foregroundStyle(Color("Teal"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color("TealLight"))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(Color("CardBackground").opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color("Stone500").opacity(0.12), lineWidth: 1)
        )
    }
}
