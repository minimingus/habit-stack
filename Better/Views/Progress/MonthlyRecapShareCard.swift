import SwiftUI

struct MonthlyRecapShareCard: View {
    let monthName: String
    let completionRate: Double
    let habitsCompleted: Int
    let identityVotes: Int
    let topHabitName: String?
    let topHabitEmoji: String?

    private var ratePercent: Int { Int(completionRate * 100) }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#0f172a"), Color(hex: "#1e293b")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color(hex: "#0D9488").opacity(0.18))
                .blur(radius: 40)
                .frame(width: 200, height: 200)
                .offset(y: -60)

            VStack(spacing: 0) {
                Spacer()

                Text("📊")
                    .font(.system(size: 64))
                    .padding(.bottom, 16)

                Text("\(monthName) Recap")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.bottom, 20)

                // Stats grid
                HStack(spacing: 24) {
                    statItem(value: "\(ratePercent)%", label: "Completion")
                    statItem(value: "\(habitsCompleted)", label: "Completed")
                    statItem(value: "\(identityVotes)", label: "Votes Cast")
                }
                .padding(.bottom, 20)

                if let name = topHabitName, let emoji = topHabitEmoji {
                    Text("Strongest: \(emoji) \(name)")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color(hex: "#94a3b8"))
                }

                Text("Building identity, one vote at a time.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(hex: "#64748b"))
                    .padding(.top, 8)

                Spacer()

                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(Color(hex: "#0D9488"))
                        Text("Better You")
                            .font(.caption.bold())
                            .foregroundStyle(Color(hex: "#94a3b8"))
                    }
                    Text("Download on the App Store")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color(hex: "#64748b"))
                }
                .padding(.bottom, 24)
            }
        }
        .frame(width: 300, height: 420)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color(hex: "#64748b"))
        }
    }
}
