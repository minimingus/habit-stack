import SwiftUI

struct HabitDetailView: View {
    let habit: Habit
    let streak: Streak?
    let anchorName: String?
    let onEdit: () -> Void
    let onArchive: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showArchiveAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Hero header
                    VStack(spacing: 8) {
                        Text(habit.emoji)
                            .font(.system(size: 56))
                        Text(habit.name)
                            .font(.title2.bold())
                            .foregroundStyle(Color("Stone950"))
                        if let streak, streak.currentStreak > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .foregroundStyle(.orange)
                                Text("\(streak.currentStreak)-day streak")
                                    .font(.subheadline)
                                    .foregroundStyle(Color("Stone500"))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)

                    // Streak stats
                    if let streak {
                        HStack(spacing: 0) {
                            StatCell(label: "Current Streak", value: "\(streak.currentStreak)")
                            Divider().frame(height: 40)
                            StatCell(label: "Longest Streak", value: "\(streak.longestStreak)")
                        }
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                        .padding(.horizontal, 16)
                    }

                    // Four Laws breakdown
                    VStack(spacing: 1) {
                        LawRow(
                            law: "Make it Obvious",
                            icon: "eye",
                            values: [
                                habit.cue.map { "Cue: \($0)" },
                                anchorName.map { "After: \($0)" }
                            ].compactMap { $0 }
                        )
                        LawRow(
                            law: "Make it Attractive",
                            icon: "heart",
                            values: [habit.craving].compactMap { $0 }
                        )
                        LawRow(
                            law: "Make it Easy",
                            icon: "bolt",
                            values: [
                                habit.tinyVersion.map { "2-min version: \($0)" },
                                "When: \(habit.timeOfDay.displayName)",
                                "Frequency: \(habit.frequency.rawValue.capitalized)"
                            ].compactMap { $0 }
                        )
                        LawRow(
                            law: "Make it Satisfying",
                            icon: "star",
                            values: [
                                habit.reward,
                                habit.reminderEnabled ? habit.reminderTime.map { "Reminder: \(timeString($0))" } : nil
                            ].compactMap { $0?.isEmpty == false ? $0 : nil }
                        )
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                    .padding(.horizontal, 16)

                    // Identity statement
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Identity")
                            .font(.caption.bold())
                            .foregroundStyle(Color("Stone500"))
                            .padding(.horizontal, 16)
                        Text("I am becoming the type of person who \(habit.name.lowercased()).")
                            .font(.subheadline.italic())
                            .foregroundStyle(Color("Stone950"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color("TealLight"))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 16)
                    }

                    // Actions
                    VStack(spacing: 10) {
                        Button {
                            dismiss()
                            onEdit()
                        } label: {
                            Label("Edit Habit", systemImage: "pencil")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("Teal"))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Button {
                            showArchiveAlert = true
                        } label: {
                            Label("Archive Habit", systemImage: "archivebox")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("Stone100"))
                                .foregroundStyle(Color("Stone950"))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .background(Color("Stone100").ignoresSafeArea())
            .navigationTitle("Habit Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Archive Habit?", isPresented: $showArchiveAlert) {
                Button("Archive", role: .destructive) {
                    dismiss()
                    onArchive()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This habit will be archived and removed from your daily view.")
            }
        }
    }

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
}

private struct StatCell: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(Color("Teal"))
            Text(label)
                .font(.caption)
                .foregroundStyle(Color("Stone500"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

private struct LawRow: View {
    let law: String
    let icon: String
    let values: [String]

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(Color("Teal"))
                .frame(width: 20)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 4) {
                Text(law)
                    .font(.caption.bold())
                    .foregroundStyle(Color("Stone500"))
                if values.isEmpty {
                    Text("Not set")
                        .font(.subheadline)
                        .foregroundStyle(Color("Stone500").opacity(0.6))
                        .italic()
                } else {
                    ForEach(values, id: \.self) { value in
                        Text(value)
                            .font(.subheadline)
                            .foregroundStyle(Color("Stone950"))
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
    }
}
