import SwiftUI

struct WeeklyReflectionView: View {
    let habitStats: [(name: String, emoji: String, completionRate: Double)]
    let onDismiss: () -> Void
    var onSnooze: (() -> Void)? = nil

    @State private var easiest = ""
    @State private var hardest = ""
    @State private var adjustment = ""
    @FocusState private var focusedField: Field?

    private enum Field { case easiest, hardest, adjustment }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Weekly Reflection")
                            .font(.title2.bold())
                            .foregroundStyle(Color("Stone950"))
                        Text("A few minutes of honest reflection compounds like interest.")
                            .font(.subheadline)
                            .foregroundStyle(Color("Stone500"))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Completion stats
                    if !habitStats.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("This week")
                                .font(.headline)
                                .padding(.horizontal, 20)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(habitStats, id: \.name) { stat in
                                        HabitStatChip(emoji: stat.emoji, name: stat.name, rate: stat.completionRate)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }

                    // Questions
                    VStack(spacing: 16) {
                        ReflectionField(
                            number: 1,
                            question: "Which habit felt easiest this week?",
                            placeholder: "e.g. Morning walk",
                            text: $easiest
                        )
                        .focused($focusedField, equals: .easiest)

                        ReflectionField(
                            number: 2,
                            question: "Which was hardest?",
                            placeholder: "e.g. Reading before bed",
                            text: $hardest
                        )
                        .focused($focusedField, equals: .hardest)

                        ReflectionField(
                            number: 3,
                            question: "What will you adjust next week?",
                            placeholder: "e.g. Move gym to mornings",
                            text: $adjustment
                        )
                        .focused($focusedField, equals: .adjustment)
                    }
                    .padding(.horizontal, 20)

                    // Save button
                    Button(action: save) {
                        Text("Save Reflection")
                            .font(.body.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color("Teal"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Menu {
                        Button("Later") { onDismiss() }
                        if let snooze = onSnooze {
                            Button("Remind me in 4 hours") { snooze() }
                        }
                    } label: {
                        Text("Later")
                            .foregroundStyle(Color("Stone500"))
                    }
                }
            }
        }
    }

    private func save() {
        // Store answers locally in UserDefaults
        let reflection: [String: String] = [
            "easiest": easiest,
            "hardest": hardest,
            "adjustment": adjustment,
            "date": ISO8601DateFormatter().string(from: Date())
        ]
        var history = UserDefaults.standard.array(forKey: "weeklyReflections") as? [[String: String]] ?? []
        history.append(reflection)
        UserDefaults.standard.set(history, forKey: "weeklyReflections")
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastWeeklyReflectionDate")
        HapticManager.notification(.success)
        onDismiss()
    }
}

private struct ReflectionField: View {
    let number: Int
    let question: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color("Teal"))
                        .frame(width: 22, height: 22)
                    Text("\(number)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                }
                Text(question)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color("Stone950"))
            }

            TextField(placeholder, text: $text, axis: .vertical)
                .lineLimit(2...4)
                .padding(12)
                .background(Color("Stone100"))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

private struct HabitStatChip: View {
    let emoji: String
    let name: String
    let rate: Double

    var body: some View {
        VStack(spacing: 4) {
            Text(emoji)
                .font(.title2)
            Text("\(Int(rate * 100))%")
                .font(.caption.bold())
                .foregroundStyle(rate >= 0.7 ? Color("Teal") : Color("Stone500"))
            Text(name)
                .font(.caption2)
                .foregroundStyle(Color("Stone500"))
                .lineLimit(1)
                .frame(width: 64)
        }
        .padding(10)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}
