import SwiftUI

struct WelcomeView: View {
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 16) {
                Text("HabitStack")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(Color("Teal"))

                Text("Build better habits, one tiny step at a time.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color("Stone500"))
            }
            .padding(.horizontal)

            VStack(spacing: 12) {
                FeatureRow(icon: "checkmark.circle.fill", text: "Track habits using Atomic Habits methodology")
                FeatureRow(icon: "flame.fill", text: "Build streaks and never miss twice")
                FeatureRow(icon: "bubble.left.fill", text: "AI Coach grounded in James Clear's system")
            }
            .padding(.horizontal, 32)

            Spacer()

            Button(action: onStart) {
                Text("Get Started")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("Teal"))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color("Teal"))
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color("Stone950"))
            Spacer()
        }
    }
}
