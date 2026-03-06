import SwiftUI

struct WizardStepRoutineView: View {
    @Bindable var viewModel: HabitWizardViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Make it Easy")
                        .font(.headline)
                    Text("Reduce friction. Start with a version so easy you can't say no — the 2-Minute Rule.")
                        .font(.subheadline)
                        .foregroundStyle(Color("Stone500"))
                }

                FormSection(title: "2-Minute Version") {
                    TextField("e.g. Put on my running shoes", text: $viewModel.tinyVersion)
                        .padding()
                        .background(Color("Stone100"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                FormSection(title: "Time of Day") {
                    Picker("Time of Day", selection: $viewModel.timeOfDay) {
                        ForEach(Habit.TimeOfDay.allCases, id: \.self) { tod in
                            Text(tod.displayName).tag(tod)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                FormSection(title: "Frequency") {
                    Picker("Frequency", selection: $viewModel.frequency) {
                        ForEach(Habit.Frequency.allCases, id: \.self) { f in
                            Text(f.rawValue.capitalized).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .padding(24)
        }
    }
}
