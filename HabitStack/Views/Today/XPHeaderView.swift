import SwiftUI

struct XPHeaderView: View {
    let profile: Profile

    private var xpForNextLevel: Int { profile.level * 100 }
    private var xpProgress: Double {
        let base = (profile.level - 1) * 100
        let earned = profile.xpTotal - base
        return min(1.0, max(0, Double(earned) / Double(xpForNextLevel - base)))
    }

    var body: some View {
        HStack(spacing: 12) {
            // Level badge
            ZStack {
                Circle()
                    .fill(Color("Teal"))
                    .frame(width: 36, height: 36)
                Text("L\(profile.level)")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(profile.xpTotal) XP")
                        .font(.caption.bold())
                        .foregroundStyle(Color("Stone950"))
                    Spacer()
                    Text("→ Level \(profile.level + 1) at \(xpForNextLevel) XP")
                        .font(.caption2)
                        .foregroundStyle(Color("Stone500"))
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color("Stone100"))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color("Teal"))
                            .frame(width: geo.size.width * xpProgress, height: 6)
                            .animation(.easeInOut(duration: 0.5), value: xpProgress)
                    }
                }
                .frame(height: 6)
            }

            if profile.streakShields > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "shield.fill")
                        .foregroundStyle(Color("Teal"))
                        .font(.caption)
                    Text("\(profile.streakShields)")
                        .font(.caption.bold())
                        .foregroundStyle(Color("Teal"))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

struct XPToastView: View {
    let amount: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill")
                .foregroundStyle(.yellow)
            Text("+\(amount) XP")
                .font(.subheadline.bold())
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color("Teal"))
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
    }
}
