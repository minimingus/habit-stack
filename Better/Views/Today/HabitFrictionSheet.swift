import SwiftUI

struct HabitFrictionSheet: View {
    let habit: Habit
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var tinyVersion: String
    @State private var reminderEnabled: Bool
    @State private var reminderTime: Date
    @FocusState private var tinyFocused: Bool

    init(habit: Habit, onSave: @escaping () -> Void) {
        self.habit = habit
        self.onSave = onSave
        _tinyVersion = State(initialValue: habit.tinyVersion ?? "")
        _reminderEnabled = State(initialValue: habit.reminderEnabled)
        _reminderTime = State(initialValue: habit.reminderTime ?? Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date())
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("What's the 2-minute version?")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color("Stone500"))
                    TextField("e.g. Just put on my shoes", text: $tinyVersion)
                        .focused($tinyFocused)
                        .padding(12)
                        .background(Color("Stone100"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Enable daily reminder", isOn: $reminderEnabled)
                        .tint(Color("Teal"))
                    if reminderEnabled {
                        DatePicker("Reminder time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .tint(Color("Teal"))
                    }
                }
                .padding(12)
                .background(Color("Stone100"))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Spacer()
            }
            .padding(20)
            .background(Color("AppBackground").ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    Button("Done") { tinyFocused = false }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .navigationTitle("Set up \(habit.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color("Stone500"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("Teal"))
                }
            }
        }
        .presentationDetents([.medium])
    }

    @MainActor
    private func save() async {
        let trimmed = tinyVersion.trimmingCharacters(in: .whitespaces)
        let tinyChanged = trimmed != (habit.tinyVersion ?? "")
        let reminderChanged = reminderEnabled != habit.reminderEnabled || (reminderEnabled && reminderTime != habit.reminderTime)
        guard tinyChanged || reminderChanged else { dismiss(); return }
        var updated = habit
        updated.tinyVersion = trimmed.isEmpty ? nil : trimmed
        updated.reminderEnabled = reminderEnabled
        updated.reminderTime = reminderEnabled ? reminderTime : nil
        do {
            try await HabitService.shared.updateHabit(updated)
            onSave()
            dismiss()
        } catch {
            // silently ignore — sheet stays open, data unchanged
        }
    }
}
