import SwiftUI

struct WizardStepCravingView: View {
    @Bindable var viewModel: HabitWizardViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Make it Attractive")
                        .font(.headline)
                    Text("Link your habit to something you want. The more attractive a habit is, the more likely you are to repeat it.")
                        .font(.subheadline)
                        .foregroundStyle(Color("Stone500"))
                }

                FormSection(title: "Why does this matter to you?") {
                    TextField("e.g. I want to feel energized and focused...", text: $viewModel.craving, axis: .vertical)
                        .lineLimit(3...6)
                        .padding()
                        .background(Color("Stone100"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                FormSection(title: "Temptation Bundle (Optional)") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("I will [habit] WHILE [something I enjoy]")
                            .font(.caption)
                            .foregroundStyle(Color("Stone500"))
                        TextField("e.g. I'll meditate while drinking my morning coffee", text: $viewModel.craving, axis: .vertical)
                            .lineLimit(2...4)
                            .padding()
                            .background(Color("Stone100"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .padding(24)
        }
    }
}
