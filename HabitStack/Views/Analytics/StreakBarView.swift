import SwiftUI

struct StreakBarView: View {
    let streak: Streak

    private let milestones = [7, 14, 21, 30, 66, 100]

    private var nextMilestone: Int? {
        milestones.first { $0 > streak.currentStreak }
    }

    private var milestoneProgress: Double {
        guard let next = nextMilestone else { return 1.0 }
        let prev = milestones.last { $0 < next } ?? 0
        let span = next - prev
        let done = streak.currentStreak - prev
        return span > 0 ? Double(done) / Double(span) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Streaks")
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

                if let next = nextMilestone {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Next milestone")
                            .font(.caption)
                            .foregroundStyle(Color("Stone500"))
                        Text("\(next - streak.currentStreak) days away")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color("Stone950"))
                    }
                }
            }

            // Progress toward next milestone
            if let next = nextMilestone {
                VStack(alignment: .leading, spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color("Stone100"))
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color("Teal"))
                                .frame(width: geo.size.width * milestoneProgress, height: 8)
                                .animation(.spring(duration: 0.6), value: milestoneProgress)
                        }
                    }
                    .frame(height: 8)
                    Text("toward \(next)-day milestone")
                        .font(.caption2)
                        .foregroundStyle(Color("Stone500"))
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}
