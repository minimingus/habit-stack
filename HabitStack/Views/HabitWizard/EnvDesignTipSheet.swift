import SwiftUI

struct EnvDesignTipSheet: View {
    let habitName: String
    let tipText: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color("TealLight"))
                        .frame(width: 72, height: 72)
                    Image(systemName: "eye.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color("Teal"))
                }

                VStack(spacing: 8) {
                    Text("Make It Obvious")
                        .font(.title2.bold())
                        .foregroundStyle(Color("Stone950"))

                    Text(tipText)
                        .font(.body)
                        .foregroundStyle(Color("Stone500"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            Button("Got It") {
                dismiss()
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color("Teal"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .background(Color("AppBackground").ignoresSafeArea())
        .presentationDetents([.medium])
    }
}
