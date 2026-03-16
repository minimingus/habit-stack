import SwiftUI

struct WizardStepCravingView: View {
    @Bindable var viewModel: HabitWizardViewModel

    private static let identitySuggestions = [
        "reads every day",
        "exercises regularly",
        "meditates daily",
        "eats healthy",
        "sleeps well",
        "journals daily",
        "stays hydrated",
        "learns continuously",
    ]

    private var filteredIdentities: [String] {
        let q = viewModel.craving.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return Self.identitySuggestions }
        return Self.identitySuggestions.filter { $0.localizedCaseInsensitiveContains(q) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Make it Attractive")
                        .font(.headline)
                    Text("Habits stick when they match who you want to be.")
                        .font(.subheadline)
                        .foregroundStyle(Color("Stone500"))
                }

                FormSection(title: "Who do you want to become?") {
                    VStack(alignment: .leading, spacing: 10) {
                        if !filteredIdentities.isEmpty {
                            ChipGrid(spacing: 8) {
                                ForEach(filteredIdentities, id: \.self) { suggestion in
                                    SuggestionChip(
                                        label: suggestion,
                                        isSelected: viewModel.craving == suggestion
                                    ) {
                                        viewModel.craving = suggestion
                                    }
                                }
                            }
                            .animation(.easeInOut(duration: 0.2), value: filteredIdentities)
                        }
                        TextField("Or add a personal identity…", text: $viewModel.craving)
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
