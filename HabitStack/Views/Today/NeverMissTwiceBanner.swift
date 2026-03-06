import SwiftUI

struct NeverMissTwiceBanner: View {
    var missedCount: Int = 0
    let onDismiss: () -> Void

    private var subtitle: String {
        if missedCount > 1 {
            return "\(missedCount) habits missed yesterday — never miss twice."
        }
        return "Rule: Never miss twice. Start again today."
    }

    var body: some View {
        HStack(spacing: 12) {
            Text("💪")
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text("You missed yesterday. That's okay.")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color("Stone950"))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color("Stone500"))
            }

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption.bold())
                    .foregroundStyle(Color("Stone500"))
                    .padding(6)
                    .background(Color("Stone100"))
                    .clipShape(Circle())
            }
        }
        .padding(14)
        .background(Color("TealLight"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color("Teal").opacity(0.3), lineWidth: 1)
        )
    }
}
