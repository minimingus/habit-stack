import SwiftUI

struct DailyInsightCard: View {
    @State private var dismissed = false

    private static let insights: [String] = [
        "You do not rise to the level of your goals. You fall to the level of your systems.",
        "Every action you take is a vote for the type of person you wish to become.",
        "The most effective way to change who you are is to change what you do.",
        "Small habits don't add up — they compound.",
        "You don't have to be the victim of your environment. You can also be the architect of it.",
        "Make it obvious. Make it attractive. Make it easy. Make it satisfying.",
        "Success is the product of daily habits — not once-in-a-lifetime transformations.",
        "The goal is not to read a book, but to become a reader.",
        "Habits are the compound interest of self-improvement.",
        "Missing once is an accident. Missing twice is the start of a new habit.",
        "Professionals stick to the schedule; amateurs let life get in the way.",
        "The first mistake is never the one that ruins you. It is the spiral of repeated mistakes.",
        "A small habit will change your life. An obsession with trying to change everything will paradict you.",
        "Identity is not what you want to achieve. It is who you believe you are.",
        "Each habit not only gets results but also teaches you something far more important: to trust yourself.",
        "The secret to getting results that last is to never stop making improvements.",
        "When you fall in love with the process rather than the product, you don't have to wait to give yourself permission to be happy.",
        "Reduce the friction associated with good behaviors. Increase the friction associated with bad behaviors.",
        "The 2-Minute Rule: Make it so easy you can't say no.",
        "Your current habits are perfectly designed to deliver your current results.",
        "Environment is the invisible hand that shapes human behavior.",
        "The most powerful outcomes are delayed. Be patient.",
        "Behavior that is immediately rewarded gets repeated. Behavior that is immediately punished gets avoided.",
        "Every craving is linked to a desire to change your internal state.",
        "A habit must be established before it can be improved.",
        "Implementation intention: I will [behavior] at [time] in [location].",
        "Habit stacking: After I [current habit], I will [new habit].",
        "The costs of your bad habits are in the future. The rewards are in the present.",
        "It's not about any single accomplishment. It is about the cycle of endless refinement and continuous improvement.",
        "You should be far more concerned with your current trajectory than with your current results.",
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
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
            .onAppear {
                dismissed = UserDefaults.standard.bool(forKey: dismissKey)
            }
        }
    }
}
