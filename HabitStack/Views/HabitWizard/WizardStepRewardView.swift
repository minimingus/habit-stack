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
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Self.rewardSuggestions, id: \.self) { reward in
                                    Button {
                                        viewModel.reward = reward
                                    } label: {
                                        Text(reward)
                                            .font(.subheadline)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 7)
                                            .background(viewModel.reward == reward ? Color("Teal") : Color("Stone100"))
                                            .foregroundStyle(viewModel.reward == reward ? .white : Color("Stone950"))
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
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
