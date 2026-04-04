import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let headline: String
    let subtext: String
    var cta: String? = nil
    var onCTA: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(Color("Stone500").opacity(0.5))
            Text(headline)
                .font(.headline)
                .foregroundStyle(Color("Stone950"))
            Text(subtext)
                .font(.subheadline)
                .foregroundStyle(Color("Stone500"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            if let cta, let onCTA {
                Button(cta, action: onCTA)
                    .buttonStyle(.borderedProminent)
                    .tint(Color("Teal"))
            }
            Spacer()
        }
    }
}
