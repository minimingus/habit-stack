import SwiftUI

struct WizardStepRewardView: View {
    @Bindable var viewModel: HabitWizardViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Make it Satisfying")
                        .font(.headline)
                    Text("The final step is to give your habit an immediate reward. What makes this feel good right after doing it?")
                        .font(.subheadline)
                        .foregroundStyle(Color("Stone500"))
                }

                FormSection(title: "Immediate Reward") {
                    TextField("e.g. 5 minutes of reading news guilt-free", text: $viewModel.reward)
                        .padding()
                        .background(Color("Stone100"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
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
