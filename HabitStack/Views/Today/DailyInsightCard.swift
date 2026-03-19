import SwiftUI

struct DailyInsightCard: View {
    @State private var dismissed = false

    private static let insights: [String] = [
        "Showing up today is more important than being perfect.",
        "Small actions, repeated, become who you are.",
        "You don't need motivation. You need a routine.",
        "Consistency isn't exciting. That's why it works.",
        "One rep counts more than zero. Always.",
        "The days you don't feel like it are the ones that matter most.",
        "Progress is quiet. Trust the process.",
        "What you do daily defines you more than what you do occasionally.",
        "Two minutes of effort beats two hours of planning to start tomorrow.",
        "Missing once is human. Missing twice is a choice.",
        "Your environment shapes your behavior. Design it well.",
        "The best routine is the one you actually follow.",
        "Don't aim for the best version of yourself today. Aim for a slightly better one.",
        "You're not behind. You're exactly where consistency will take you.",
        "Boredom is part of the deal. Keep going anyway.",
        "Stack a new habit onto something you already do.",
        "Make the right thing the easy thing.",
        "A 1% improvement today is invisible. A year of them is not.",
        "Your trajectory matters more than your position.",
        "Reduce friction for the habits you want. Add friction for the ones you don't.",
        "Tie each habit to the person you want to become.",
        "Reward yourself immediately after a hard habit. Your brain will thank you.",
        "You don't break a habit. You replace it with a better one.",
        "Track your consistency, not your intensity.",
        "The goal isn't to do more. It's to not stop.",
        "When in doubt, just start. Momentum follows action.",
        "Good days build confidence. Hard days build character. Both build habits.",
        "The version of you one year from now is shaped by what you do today.",
        "Discipline is a practice, not a personality trait.",
        "Showing up is the skill. Everything else is a bonus.",
    ]

    private var todayInsight: String {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return Self.insights[(day - 1) % Self.insights.count]
    }

    private var dismissKey: String {
        let date = ISO8601DateFormatter().string(from: Date()).prefix(10)
        return "insightDismissed_\(date)"
    }

    var body: some View {
        if dismissed { EmptyView() } else {
            HStack(alignment: .top, spacing: 12) {
                Text("1%")
                    .font(.caption.bold())
                    .foregroundStyle(Color("Teal"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color("TealLight"))
                    .clipShape(Capsule())

                Text(todayInsight)
                    .font(.subheadline)
                    .foregroundStyle(Color("Stone950"))
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                Button {
                    withAnimation { dismissed = true }
                    UserDefaults.standard.set(true, forKey: dismissKey)
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.bold())
                        .foregroundStyle(Color("Stone500"))
                        .padding(6)
                        .background(Color("Stone100"))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(Color("CardBackground"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
            .onAppear {
                dismissed = UserDefaults.standard.bool(forKey: dismissKey)
            }
        }
    }
}
