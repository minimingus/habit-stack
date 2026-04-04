import SwiftUI

struct TodayHeaderView: View {
    let completed: Int
    let total: Int
    let bestStreak: Int

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // Date
            Text(formattedDate())
                .font(.caption.bold())
                .foregroundStyle(Color("Stone500"))
                .tracking(0.5)

            // "Today" + count
            HStack(alignment: .lastTextBaseline) {
                Text("Today")
                    .font(.system(size: 36, weight: .heavy))
                    .foregroundStyle(Color("Stone950"))
                Spacer()
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("\(completed)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color("Teal"))
                    Text("/\(total)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color("Stone500"))
                }
            }

            // Terracotta gradient progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color("Stone100"))
                        .frame(height: 3)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [Color("Teal"), Color(red: 0.91, green: 0.57, blue: 0.48)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress, height: 3)
                        .animation(.spring(duration: 0.5), value: progress)
                }
            }
            .frame(height: 3)

            // Streak badge
            if bestStreak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("\(bestStreak)-day streak")
                        .font(.caption.bold())
                        .foregroundStyle(Color("Teal"))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color("TealLight"))
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 14)
        .background(Color("CardBackground"))
    }

    private func formattedDate() -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: Date()).uppercased()
    }
}
