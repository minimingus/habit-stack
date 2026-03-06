import SwiftUI

struct ProgressRingView: View {
    let progress: Double
    let completed: Int
    let total: Int

    @State private var animatedProgress: Double = 0

    var body: some View {
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
        .padding(.vertical, 16)
        .onAppear { animatedProgress = progress }
        .onChange(of: progress) { _, new in animatedProgress = new }
    }
}
