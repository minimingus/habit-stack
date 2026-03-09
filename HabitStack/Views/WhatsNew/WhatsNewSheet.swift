import SwiftUI

struct WhatsNewSheet: View {
    let features: [WhatsNewFeature]
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 6) {
                Text("What's New")
                    .font(.title2.bold())
                    .foregroundStyle(Color("Stone950"))
                Text(features.count == 1
                     ? "1 new thing since your last visit"
                     : "\(features.count) new things since your last visit")
                    .font(.subheadline)
                    .foregroundStyle(Color("Stone500"))
            }
            .padding(.top, 28)
            .padding(.bottom, 24)
            .padding(.horizontal, 24)

            // Feature cards
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(features) { feature in
                        FeatureCard(feature: feature)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }

            // Dismiss button
            Button(action: onDismiss) {
                Text("Got it")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color("Teal"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Color("AppBackground").ignoresSafeArea())
        .interactiveDismissDisabled(true)
    }
}

// MARK: - Feature Card

private struct FeatureCard: View {
    let feature: WhatsNewFeature

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(feature.emoji)
                .font(.title)
                .frame(width: 44, height: 44)
                .background(Color("Stone100"))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.headline)
                    .foregroundStyle(Color("Stone950"))
                Text(feature.body)
                    .font(.subheadline)
                    .foregroundStyle(Color("Stone500"))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
    }
}
