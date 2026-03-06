import SwiftUI

struct NotificationPermissionView: View {
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color("Teal"))

                Text("Stay on Track")
                    .font(.title2.bold())

                Text("Enable reminders to get notified when it's time for your habits. You can customize times for each habit.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color("Stone500"))
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 8) {
                PermissionBenefit(icon: "clock.fill", text: "Timely reminders at your preferred time")
                PermissionBenefit(icon: "flame.fill", text: "Streak protection notifications")
                PermissionBenefit(icon: "checkmark.circle.fill", text: "Daily completion summaries")
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    Task {
                        _ = await NotificationManager.shared.requestPermission()
                        onComplete()
                    }
                } label: {
                    Text("Allow Notifications")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("Teal"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button("Skip", action: onComplete)
                    .foregroundStyle(Color("Stone500"))
                    .padding()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

private struct PermissionBenefit: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color("Teal"))
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}
