import SwiftUI

struct WizardStepRoutineView: View {
    @Bindable var viewModel: HabitWizardViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Make it Easy")
                        .font(.headline)
                    Text("The 2-Minute Rule: make starting so easy you can't say no.")
                        .font(.subheadline)
                        .foregroundStyle(Color("Stone500"))
                }

                FormSection(title: "Habit Type") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Count-based goal", isOn: $viewModel.isQuantified)
                            .tint(Color("Teal"))

                        if viewModel.isQuantified {
                            HStack {
                                Text("Daily target")
                                    .font(.subheadline)
                                    .foregroundStyle(Color("Stone950"))
                                Spacer()
                                Stepper("\(viewModel.targetCount)", value: $viewModel.targetCount, in: 2...100)
                                    .fixedSize()
                            }
                            Text("e.g. 8 glasses of water, 10 push-ups, 5 pages")
                                .font(.caption)
                                .foregroundStyle(Color("Stone500"))
                        }
                    }
                    .padding()
                    .background(Color("Stone100"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
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

                FormSection(title: "Timer (optional)") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Set a duration", isOn: $viewModel.durationEnabled)
                            .tint(Color("Teal"))

                        if viewModel.durationEnabled {
                            HStack {
                                Text("\(viewModel.durationMinutes) min")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color("Teal"))
                                    .frame(width: 64)
                                Slider(
                                    value: Binding(
                                        get: { Double(viewModel.durationMinutes) },
                                        set: { viewModel.durationMinutes = Int($0) }
                                    ),
                                    in: 1...60, step: 1
                                )
                                .tint(Color("Teal"))
                            }
                            Text("A timer will appear on the habit card. Complete the session to log the habit.")
                                .font(.caption)
                                .foregroundStyle(Color("Stone500"))
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
