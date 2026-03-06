import SwiftUI

struct IdentityStatementBanner: View {
    let statement: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "person.fill.checkmark")
                .foregroundStyle(Color("Teal"))
                .font(.subheadline)

            VStack(alignment: .leading, spacing: 1) {
                Text("I am becoming someone who...")
                    .font(.caption2)
                    .foregroundStyle(Color("Stone500"))
                Text(statement)
                    .font(.caption.bold())
                    .foregroundStyle(Color("Stone950"))
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(Color("Stone500"))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color("TealLight").opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
