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
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Frequency", selection: $viewModel.frequency) {
                            ForEach(Habit.Frequency.allCases, id: \.self) { f in
                                Text(f.rawValue.capitalized).tag(f)
                            }
                        }
                        .pickerStyle(.segmented)

                        if viewModel.frequency == .custom {
                            CustomDayPicker(selectedDays: $viewModel.customDays)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: viewModel.frequency)
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

// MARK: - Custom Day Picker

private struct CustomDayPicker: View {
    @Binding var selectedDays: Set<Int>

    // 1=Sun, 2=Mon … 7=Sat
    private let days: [(label: String, value: Int)] = [
        ("S", 1), ("M", 2), ("T", 3), ("W", 4), ("T", 5), ("F", 6), ("S", 7)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Select days")
                .font(.caption)
                .foregroundStyle(Color("Stone500"))
            HStack(spacing: 6) {
                ForEach(days, id: \.value) { day in
                    let selected = selectedDays.contains(day.value)
                    Button {
                        if selected {
                            selectedDays.remove(day.value)
                        } else {
                            selectedDays.insert(day.value)
                        }
                    } label: {
                        Text(day.label)
                            .font(.caption.bold())
                            .frame(width: 34, height: 34)
                            .background(selected ? Color("Teal") : Color("Stone100"))
                            .foregroundStyle(selected ? .white : Color("Stone500"))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            if selectedDays.isEmpty {
                Text("Select at least one day")
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.7))
            }
        }
    }
}
