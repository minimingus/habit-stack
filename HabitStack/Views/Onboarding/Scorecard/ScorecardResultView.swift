import SwiftUI

struct ScorecardResultView: View {
    let result: ScorecardResult
    let onContinue: () -> Void

    @State private var animatedProgress: Double = 0

    private var overallScore: Double {
        let total = result.sleep + result.movement + result.mind + result.growth
        return Double(total) / 20.0
    }

    private var template: HabitTemplate {
        ScorecardService.templateHabit(for: result.recommended)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Text("Your Habit Scorecard")
                    .font(.title2.bold())
                    .padding(.top, 32)

                // Score ring
                ZStack {
                    Circle()
                        .stroke(Color("Stone100"), lineWidth: 12)
                    Circle()
                        .trim(from: 0, to: animatedProgress)
                        .stroke(Color("Teal"), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 4) {
                        Text("\(Int(animatedProgress * 100))%")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(Color("Teal"))
                        Text("Overall")
                            .font(.caption)
                            .foregroundStyle(Color("Stone500"))
                    }
                }
                .frame(width: 140, height: 140)
                .onAppear {
                    withAnimation(.easeOut(duration: 1.0)) {
                        animatedProgress = overallScore
                    }
                }

                // Dimension bars
                VStack(spacing: 16) {
                    ForEach(ScorecardResult.Dimension.allCases, id: \.self) { dimension in
                        DimensionBar(
                            dimension: dimension,
                            score: score(for: dimension),
                            isRecommended: dimension == result.recommended
                        )
                    }
                }
                .padding(.horizontal, 24)

                // Recommendation
                VStack(spacing: 8) {
                    Text("Your biggest opportunity")
                        .font(.caption)
                        .textCase(.uppercase)
                        .foregroundStyle(Color("Stone500"))
                    Text(result.recommended.displayName)
                        .font(.title3.bold())
                        .foregroundStyle(Color("Teal"))
                }

                Button(action: onContinue) {
                    HStack {
                        Text("Start with \(template.name)")
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("Teal"))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private func score(for dimension: ScorecardResult.Dimension) -> Int {
        switch dimension {
        case .sleep: return result.sleep
        case .movement: return result.movement
        case .mind: return result.mind
        case .growth: return result.growth
        }
    }
}

private struct DimensionBar: View {
    let dimension: ScorecardResult.Dimension
    let score: Int
    let isRecommended: Bool

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: dimension.icon)
                    .foregroundStyle(isRecommended ? Color("Teal") : Color("Stone500"))
                Text(dimension.displayName)
                    .font(.subheadline)
                    .foregroundStyle(isRecommended ? Color("Stone950") : Color("Stone500"))
                    .fontWeight(isRecommended ? .semibold : .regular)
                Spacer()
                Text("\(score)/5")
                    .font(.caption)
                    .foregroundStyle(Color("Stone500"))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color("Stone100"))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isRecommended ? Color("Teal") : Color("TealLight"))
                        .frame(width: geo.size.width * Double(score) / 5.0, height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}
