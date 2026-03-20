import SwiftUI
import PostHog

struct UpgradeNudgeCard: View {
    let onUpgrade: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("You've been building habits for a month")
                        .font(.subheadline.bold())
                    Text("Switch to monthly and save 33%.")
                        .font(.caption)
                        .foregroundStyle(Color("Stone500"))
                }
                Spacer()
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundStyle(Color("Stone500"))
                        .padding(6)
                }
            }

            HStack(spacing: 10) {
                Button {
                    PostHogSDK.shared.capture("plan_upgrade_nudge_tapped", properties: ["action": "upgrade"])
                    onUpgrade()
                } label: {
                    Text("Switch to Monthly ($7.99/mo)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color("Teal"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    PostHogSDK.shared.capture("plan_upgrade_nudge_dismissed")
                    onDismiss()
                } label: {
                    Text("Maybe later")
                        .font(.caption)
                        .foregroundStyle(Color("Stone500"))
                }
            }
        }
        .padding(14)
        .background(Color("Stone100"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            PostHogSDK.shared.capture("plan_upgrade_nudge_shown")
        }
    }
}
