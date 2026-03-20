import SwiftUI

struct TrialExpiryBanner: View {
    let onUpgrade: () -> Void

    var body: some View {
        Button(action: onUpgrade) {
            HStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.title3)
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Pro trial ends today")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                    Text("Tap to keep unlimited access")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }

                Spacer()

                Text("Upgrade")
                    .font(.caption.bold())
                    .foregroundStyle(Color("Teal"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.white)
                    .clipShape(Capsule())
            }
            .padding(12)
            .background(Color("Teal"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
