import SwiftUI

/// Standalone card used both as a preview and rendered to an image via ImageRenderer.
struct StreakShareCard: View {
    let streakDays: Int
    let habitName: String
    let milestoneName: String
    let milestoneEmoji: String

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "#0f172a"), Color(hex: "#1e293b")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle teal glow behind emoji
            Circle()
                .fill(Color(hex: "#0D9488").opacity(0.18))
                .blur(radius: 40)
                .frame(width: 200, height: 200)
                .offset(y: -40)

            VStack(spacing: 0) {
                Spacer()

                Text(milestoneEmoji)
                    .font(.system(size: 72))
                    .padding(.bottom, 20)

                Text(milestoneName)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.bottom, 8)

                if streakDays > 0 {
                    Text("\(streakDays) days of \(habitName)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color(hex: "#94a3b8"))
                        .padding(.bottom, 4)
                }

                Text("One rep at a time.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(hex: "#64748b"))
                    .padding(.top, 4)

                Spacer()

                // Watermark
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundStyle(Color(hex: "#0D9488"))
                    Text("Better You")
                        .font(.caption.bold())
                        .foregroundStyle(Color(hex: "#94a3b8"))
                }
                .padding(.bottom, 24)
            }
        }
        .frame(width: 300, height: 420)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}
