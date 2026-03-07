import SwiftUI

struct ProgressRingView: View {
    let progress: Double
    let completed: Int
    let total: Int
    var momentumMessage: String = ""

    @State private var animatedProgress: Double = 0

    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color("Stone100"), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(Color("Teal"), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 0.5), value: animatedProgress)
                VStack(spacing: 1) {
                    Text("\(completed)/\(total)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color("Stone950"))
                    Text("\(Int(animatedProgress * 100))%")
                        .font(.caption2.bold())
                        .foregroundStyle(Color("Teal"))
                    Text("done")
                        .font(.caption2)
                        .foregroundStyle(Color("Stone500"))
                }
            }
            .frame(width: 100, height: 100)

            if !momentumMessage.isEmpty {
                Text(momentumMessage)
                    .font(.title3.bold())
                    .foregroundStyle(Color("Stone950"))
                    .multilineTextAlignment(.leading)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                    .id(momentumMessage)
                    .animation(.easeInOut, value: momentumMessage)
            }
        }
        .padding(.vertical, 16)
        .onAppear { animatedProgress = progress }
        .onChange(of: progress) { _, new in animatedProgress = new }
    }
}
