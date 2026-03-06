import SwiftUI

struct ScorecardQuestionView: View {
    let dimension: ScorecardResult.Dimension
    let questionIndex: Int
    let total: Int
    let onAnswer: (Int) -> Void
    let onBack: () -> Void
    let onSkip: () -> Void

    private var question: String {
        switch dimension {
        case .sleep: return "How well are you sleeping each night?"
        case .movement: return "How often do you move your body each day?"
        case .mind: return "How well do you manage stress and mental clarity?"
        case .growth: return "How consistently do you learn or grow each week?"
        }
    }

    private let options = [
        (score: 1, label: "Struggling"),
        (score: 2, label: "Below average"),
        (score: 3, label: "Average"),
        (score: 4, label: "Good"),
        (score: 5, label: "Excellent")
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if questionIndex > 0 {
                    Button(action: onBack) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundStyle(Color("Stone500"))
                    }
                    .padding()
                } else {
                    Spacer().frame(width: 60)
                }
                Spacer()
                Button("Skip", action: onSkip)
                    .foregroundStyle(Color("Stone500"))
                    .padding()
            }

            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<total, id: \.self) { i in
                    Circle()
                        .fill(i == questionIndex ? Color("Teal") : Color("Stone100"))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 32)

            VStack(spacing: 24) {
                Image(systemName: dimension.icon)
                    .font(.system(size: 48))
                    .foregroundStyle(Color("Teal"))

                Text(question)
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            VStack(spacing: 12) {
                ForEach(options, id: \.score) { option in
                    Button {
                        HapticManager.impact(.medium)
                        onAnswer(option.score)
                    } label: {
                        Text(option.label)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("Stone100"))
                            .foregroundStyle(Color("Stone950"))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}
