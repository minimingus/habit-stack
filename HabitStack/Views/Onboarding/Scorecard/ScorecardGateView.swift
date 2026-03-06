import SwiftUI

struct ScorecardGateView: View {
    let onTakeScorecard: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.system(size: 64))
                    .foregroundStyle(Color("Teal"))

                Text("Want a personalized start?")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text("Answer 4 quick questions and we'll recommend the best habit to start with based on your current lifestyle.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color("Stone500"))
            }
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                Button(action: onTakeScorecard) {
                    Text("Take the Scorecard")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("Teal"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button(action: onSkip) {
                    Text("Skip for now")
                        .foregroundStyle(Color("Stone500"))
                        .padding()
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}
