import SwiftUI

struct NeverMissTwiceBanner: View {
    var state: NeverMissTwiceState = .warning
    var missedCount: Int = 0
    var profile: Profile?
    let onDismiss: () -> Void
    let onUseShield: () -> Void

    var body: some View {
        switch state {
        case .warning:
            warningBanner
        case .comeback:
            comebackBanner
        case .dismissed:
            EmptyView()
        }
    }

    private var warningBanner: some View {
        HStack(spacing: 12) {
            Text("💪").font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text("You missed yesterday. That's okay.")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color("Stone950"))
                Text(missedCount > 1
                     ? "\(missedCount) habits missed yesterday — never miss twice."
                     : "Rule: Never miss twice. Start again today.")
                    .font(.caption)
                    .foregroundStyle(Color("Stone500"))
            }
            Spacer()
            VStack(spacing: 6) {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption.bold())
                        .foregroundStyle(Color("Stone500"))
                        .padding(6)
                        .background(Color("Stone100"))
                        .clipShape(Circle())
                }
                if let profile, profile.level >= 5, profile.streakShields > 0 {
                    Button(action: onUseShield) {
                        HStack(spacing: 3) {
                            Image(systemName: "shield.fill")
                            Text("Use Shield")
                        }
                        .font(.caption.bold())
                        .foregroundStyle(Color("Teal"))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(Color("TealLight"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color("Teal").opacity(0.3), lineWidth: 1))
    }

    private var comebackBanner: some View {
        HStack(spacing: 12) {
            Text("🔥").font(.title2)
            Text("You're back. Streak lives on.")
                .font(.subheadline.bold())
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(14)
        .background(Color("Teal"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
