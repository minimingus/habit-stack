import SwiftUI

struct StreakBarView: View {
    let streak: Streak

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Streaks & XP")
                .font(.headline)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current")
                        .font(.caption)
                        .foregroundStyle(Color("Stone500"))
                    HStack(spacing: 4) {
                        Text("🔥")
                        Text("\(streak.currentStreak) days")
                            .font(.title3.bold())
                            .foregroundStyle(Color("Teal"))
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Best")
                        .font(.caption)
                        .foregroundStyle(Color("Stone500"))
                    HStack(spacing: 4) {
                        Text("🏆")
                        Text("\(streak.longestStreak) days")
                            .font(.title3.bold())
                            .foregroundStyle(Color("Stone950"))
                    }
                }
            }

            // Streak bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color("Stone100"))
                        .frame(height: 8)
                    if streak.longestStreak > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color("Teal"))
                            .frame(
                                width: geo.size.width * min(1, Double(streak.currentStreak) / Double(streak.longestStreak)),
                                height: 8
                            )
                    }
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}
