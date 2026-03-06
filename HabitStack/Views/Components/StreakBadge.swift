import SwiftUI

struct StreakBadge: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 2) {
            Text("🔥")
            Text("\(streak)")
                .font(.caption.bold())
                .foregroundStyle(Color("Stone950"))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color("TealLight"))
        .clipShape(Capsule())
    }
}
