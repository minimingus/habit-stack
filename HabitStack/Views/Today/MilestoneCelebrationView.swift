import SwiftUI

struct MilestoneCelebrationView: View {
    let streakDays: Int
    let habitName: String
    let onDismiss: () -> Void

    private var milestoneName: String {
        switch streakDays {
        case 0: return "Perfect Day"
        case 7: return "Week Warrior"
        case 14: return "Two Weeks Strong"
        case 21: return "Habit Forming"
        case 30: return "One Month Champion"
        case 66: return "Automatic"
        case 100: return "Centurion"
        default: return "\(streakDays)-Day Streak"
        }
    }

    private var milestoneEmoji: String {
        switch streakDays {
        case 0: return "⭐"
        case 7: return "🔥"
        case 14: return "⚡"
        case 21: return "🌱"
        case 30: return "🏆"
        case 66: return "🧠"
        case 100: return "💯"
        default: return "⭐"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text(milestoneEmoji)
                .font(.system(size: 80))
                .padding(.bottom, 20)

            VStack(spacing: 10) {
                Text(milestoneName)
                    .font(.title.bold())
                    .foregroundStyle(Color("Stone950"))

                if streakDays > 0 {
                    Text("\(streakDays) days of \(habitName)")
                        .font(.subheadline)
                        .foregroundStyle(Color("Stone500"))
                }
            }

            if streakDays == 0 {
                Text("Every habit. Every day. That's identity.")
                    .font(.body)
                    .foregroundStyle(Color("Stone500"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 24)
            } else {
                Text("Every rep makes you more of the person you want to become.")
                    .font(.body)
                    .foregroundStyle(Color("Stone500"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 24)
            }

            Spacer()

            Button(action: onDismiss) {
                Text("Keep Going")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color("Teal"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("AppBackground").ignoresSafeArea())
        .presentationDetents([.large])
    }
}
