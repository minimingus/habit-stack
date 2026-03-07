import SwiftUI

struct CompletionNoteSheet: View {
    let habitName: String
    let habitId: UUID
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var note = ""
    @FocusState private var focused: Bool

    private static let quickOptions = [
        ("💪", "Crushed it"),
        ("😌", "Felt good"),
        ("😤", "Tough but done"),
        ("😐", "Just checked it off"),
    ]

    private var noteKey: String {
        let date = ISO8601DateFormatter().string(from: Date()).prefix(10)
        return "habitNote_\(habitId.uuidString)_\(date)"
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {

                // Quick options
                VStack(alignment: .leading, spacing: 10) {
                    Text("How did it feel?")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color("Stone500"))

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(Self.quickOptions, id: \.1) { emoji, label in
                            Button {
                                note = "\(emoji) \(label)"
                                save()
                            } label: {
                                HStack(spacing: 8) {
                                    Text(emoji).font(.title3)
                                    Text(label)
                                        .font(.subheadline)
                                        .foregroundStyle(Color("Stone950"))
                                    Spacer()
                                }
                                .padding(12)
                                .background(
                                    note.contains(label) ? Color("TealLight") : Color("Stone100")
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(
                                            note.contains(label) ? Color("Teal") : Color.clear,
                                            lineWidth: 1.5
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Free text
                VStack(alignment: .leading, spacing: 6) {
                    Text("Add a personal note (optional)")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color("Stone500"))

                    TextField("e.g. Did it right after coffee", text: $note, axis: .vertical)
                        .focused($focused)
                        .lineLimit(3, reservesSpace: true)
                        .padding(12)
                        .background(Color("Stone100"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Spacer()
            }
            .padding(20)
            .background(Color("AppBackground").ignoresSafeArea())
            .navigationTitle("\(habitName) ✓")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        onDismiss()
                        dismiss()
                    }
                    .foregroundStyle(Color("Stone500"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .fontWeight(.semibold)
                    .disabled(note.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let saved = UserDefaults.standard.string(forKey: noteKey) {
                    note = saved
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func save() {
        let trimmed = note.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            UserDefaults.standard.set(trimmed, forKey: noteKey)
        }
        onDismiss()
        dismiss()
    }
}
