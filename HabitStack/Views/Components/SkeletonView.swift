import SwiftUI

struct SkeletonView: View {
    @State private var phase: CGFloat = -1

    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<5, id: \.self) { _ in
                SkeletonCard()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
}

struct SkeletonCard: View {
    @State private var phase: CGFloat = -1

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(shimmer)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(shimmer)
                    .frame(width: 140, height: 14)
                RoundedRectangle(cornerRadius: 4)
                    .fill(shimmer)
                    .frame(width: 90, height: 10)
            }

            Spacer()
        }
        .padding(12)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }

    private var shimmer: LinearGradient {
        LinearGradient(
            colors: [Color("Stone100"), Color.white.opacity(0.8), Color("Stone100")],
            startPoint: UnitPoint(x: phase - 0.3, y: 0.5),
            endPoint: UnitPoint(x: phase + 0.3, y: 0.5)
        )
    }
}
