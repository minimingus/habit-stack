import SwiftUI

struct CheckButton: View {
    let isCompleted: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(isCompleted ? Color("Teal") : Color.clear)
                    .frame(width: 32, height: 32)
                Circle()
                    .stroke(isCompleted ? Color("Teal") : Color("Stone500"), lineWidth: 2)
                    .frame(width: 32, height: 32)
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
        .animation(.spring(duration: 0.25), value: isCompleted)
    }
}
