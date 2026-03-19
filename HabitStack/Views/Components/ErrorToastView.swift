import SwiftUI

struct ErrorToastView: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.white)
            Text(message)
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.red.gradient)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
    }
}

struct ErrorToastModifier: ViewModifier {
    @Binding var errorMessage: String?
    @State private var showToast = false

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if showToast, let message = errorMessage {
                    ErrorToastView(message: message)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(100)
                }
            }
            .onChange(of: errorMessage) { _, newValue in
                guard newValue != nil else { return }
                withAnimation(.spring(duration: 0.3)) { showToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation(.spring(duration: 0.3)) { showToast = false }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        errorMessage = nil
                    }
                }
            }
    }
}

extension View {
    func errorToast(_ errorMessage: Binding<String?>) -> some View {
        modifier(ErrorToastModifier(errorMessage: errorMessage))
    }
}
