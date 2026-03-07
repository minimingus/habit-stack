import SwiftUI

struct WizardStepCravingView: View {
    @Bindable var viewModel: HabitWizardViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Make it Attractive")
                        .font(.headline)
                    Text("Identity-based habits stick. The goal isn't a habit — it's to become a certain type of person.")
                        .font(.subheadline)
                        .foregroundStyle(Color("Stone500"))
                }

                FormSection(title: "Complete this sentence") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("I am becoming the type of person who...")
                            .font(.caption)
                            .foregroundStyle(Color("Stone500"))
                        TextField("e.g. reads every day", text: $viewModel.craving)
                            .padding()
                            .background(Color("Stone100"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }

                FormSection(title: "Why does this matter? (Optional)") {
                    TextField("e.g. I want to feel energized and focused...", text: $viewModel.routine, axis: .vertical)
                        .lineLimit(3...5)
                        .padding()
                        .background(Color("Stone100"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(24)
        }
    }
}
