import SwiftUI

// MARK: - Achievement model

struct Achievement {
    let id: String
    let name: String
    let description: String
    let emoji: String
    let userDefaultsKey: String

    static let all: [Achievement] = [
        Achievement(id: "7",       name: "Week Streak",  description: "7 days in a row",      emoji: "🔥", userDefaultsKey: "achievement_milestone_7"),
        Achievement(id: "14",      name: "Two Weeks",    description: "14 days in a row",     emoji: "⚡", userDefaultsKey: "achievement_milestone_14"),
        Achievement(id: "21",      name: "Three Weeks",  description: "21 days in a row",     emoji: "💪", userDefaultsKey: "achievement_milestone_21"),
        Achievement(id: "30",      name: "One Month",    description: "30 days in a row",     emoji: "🏆", userDefaultsKey: "achievement_milestone_30"),
        Achievement(id: "66",      name: "66 Days",      description: "Habit locked in",      emoji: "🧠", userDefaultsKey: "achievement_milestone_66"),
        Achievement(id: "100",     name: "Century",      description: "100 days in a row",    emoji: "⭐", userDefaultsKey: "achievement_milestone_100"),
        Achievement(id: "perfect", name: "Perfect Day",  description: "All habits in one day", emoji: "✨", userDefaultsKey: "achievement_perfectDay"),
    ]
}

// MARK: - AchievementsView

struct AchievementsView: View {
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(.caption.bold())
                .foregroundStyle(Color("Stone500"))
                .textCase(.uppercase)
                .kerning(0.8)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Achievement.all, id: \.id) { achievement in
                    let earned = UserDefaults.standard.bool(forKey: achievement.userDefaultsKey)
                    AchievementBadge(achievement: achievement, earned: earned)
                }
            }
        }
    }
}

// MARK: - AchievementBadge

private struct AchievementBadge: View {
    let achievement: Achievement
    let earned: Bool

    var body: some View {
        VStack(spacing: 6) {
            if earned {
                Text(achievement.emoji)
                    .font(.system(size: 56))
            } else {
                Text(achievement.emoji)
                    .font(.caption)
                    .opacity(0.3)
                    .grayscale(1)
            }

            if earned {
                Text(achievement.name)
                    .font(.caption.bold())
                    .foregroundStyle(Color("Stone950"))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text(achievement.description)
                    .font(.caption)
                    .foregroundStyle(Color("Stone500"))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            } else {
                Text(achievement.name)
                    .font(.caption)
                    .foregroundStyle(Color("Stone500"))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text("Locked")
                    .font(.caption)
                    .foregroundStyle(Color("Stone500"))
            }
        }
        .padding(12)
        .frame(width: 100)
        .frame(maxHeight: .infinity)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color("Teal"), lineWidth: earned ? 1.5 : 0)
        )
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        AchievementsView()
            .padding(16)
    }
    .background(Color("AppBackground"))
}
