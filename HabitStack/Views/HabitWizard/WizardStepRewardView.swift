import SwiftUI

struct WizardStepRewardView: View {
    @Bindable var viewModel: HabitWizardViewModel

    private static let rewardSuggestions = [
        "5 min of phone",
        "Cup of coffee",
        "Short walk",
        "Favorite playlist",
        "Healthy snack",
        "5 min of reading",
    ]

    private var filteredRewards: [String] {
        let q = viewModel.reward.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return Self.rewardSuggestions }
        return Self.rewardSuggestions.filter { $0.localizedCaseInsensitiveContains(q) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Make it Satisfying")
                        .font(.headline)
                    Text("Immediate rewards reinforce the habit.")
                        .font(.subheadline)
                        .foregroundStyle(Color("Stone500"))
                }

                FormSection(title: "Immediate Reward") {
                    VStack(alignment: .leading, spacing: 10) {
                        if !filteredRewards.isEmpty {
                            ChipGrid(spacing: 8) {
                                ForEach(filteredRewards, id: \.self) { reward in
                                    SuggestionChip(
                                        label: reward,
                                        isSelected: viewModel.reward == reward
                                    ) {
                                        viewModel.reward = reward
                                    }
                                }
                            }
                            .animation(.easeInOut(duration: 0.2), value: filteredRewards)
                        }
                        TextField("Or add a personal reward…", text: $viewModel.reward)
                            .padding()
                            .background(Color("Stone100"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }

                FormSection(title: "Reminder") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Enable daily reminder", isOn: $viewModel.reminderEnabled)
                            .tint(Color("Teal"))

                        if viewModel.reminderEnabled {
                            DatePicker(
                                "Reminder time",
                                selection: $viewModel.reminderTime,
                                displayedComponents: .hourAndMinute
                            )
                            .tint(Color("Teal"))
                        }
                    }
                    .padding()
                    .background(Color("Stone100"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(24)
        }
    }
}
