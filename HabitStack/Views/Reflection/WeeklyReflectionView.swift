import SwiftUI

private enum WeekMood: String, CaseIterable {
    case crushing  = "Crushing it 🔥"
    case good      = "Felt good 👍"
    case tough     = "Tough week 💪"
    case rough     = "Rough week 😓"

    var symbol: String {
        switch self {
        case .crushing: return "flame.fill"
        case .good:     return "hand.thumbsup.fill"
        case .tough:    return "bolt.fill"
        case .rough:    return "cloud.rain.fill"
        }
    }

    var symbolColor: Color {
        switch self {
        case .crushing: return .orange
        case .good:     return Color("Teal")
        case .tough:    return .yellow
        case .rough:    return Color("Stone500")
        }
    }

    var response: String {
        switch self {
        case .crushing: return "That's the compound effect in action. Keep stacking those reps — your future self is watching."
        case .good:     return "Consistency over intensity, every time. You showed up and that's what builds identity."
        case .tough:    return "Grit is a skill. You practised it this week. Hard weeks make easy weeks possible."
        case .rough:    return "Every champion has off weeks. The rule is simple: never miss twice. You've already started."
        }
    }
}

struct WeeklyReflectionView: View {
    let habitStats: [(name: String, emoji: String, completionRate: Double)]
    let onDismiss: () -> Void
    var onSnooze: (() -> Void)? = nil

    @State private var easiest = ""
    @State private var hardest = ""
    @State private var adjustment = ""
    @State private var selectedMood: WeekMood? = nil
    @State private var savedMood: WeekMood? = nil   // non-nil = show response screen
    @FocusState private var focusedField: Field?

    private enum Field { case easiest, hardest, adjustment }

    var body: some View {
        if let mood = savedMood {
            ReflectionResponseView(mood: mood, onDone: onDismiss)
        } else {
            formBody
        }
    }

    private var formBody: some View {
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

                    // Mood picker
                    VStack(alignment: .leading, spacing: 10) {
                        Text("How was your week overall?")
                            .font(.headline)
                            .padding(.horizontal, 20)
                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible())],
                            spacing: 10
                        ) {
                            ForEach(WeekMood.allCases, id: \.self) { mood in
                                Button { selectedMood = mood } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: mood.symbol)
                                            .foregroundStyle(mood.symbolColor)
                                        Text(mood.rawValue)
                                            .font(.subheadline)
                                            .foregroundStyle(Color("Stone950"))
                                        Spacer()
                                    }
                                    .padding(12)
                                    .background(selectedMood == mood ? Color("TealLight") : Color("Stone100"))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(
                                                selectedMood == mood ? Color("Teal") : Color.clear,
                                                lineWidth: 1.5
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .animation(.easeInOut(duration: 0.15), value: selectedMood)
                    }

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
        let reflection: [String: String] = [
            "easiest": easiest,
            "hardest": hardest,
            "adjustment": adjustment,
            "mood": selectedMood?.rawValue ?? "",
            "date": ISO8601DateFormatter().string(from: Date())
        ]
        var history = UserDefaults.standard.array(forKey: "weeklyReflections") as? [[String: String]] ?? []
        history.append(reflection)
        UserDefaults.standard.set(history, forKey: "weeklyReflections")
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastWeeklyReflectionDate")
        HapticManager.notification(.success)
        if let mood = selectedMood {
            savedMood = mood   // show response screen
        } else {
            onDismiss()
        }
    }
}

// MARK: - Response screen

private struct ReflectionResponseView: View {
    let mood: WeekMood
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(mood.symbolColor.opacity(0.15))
                        .frame(width: 80, height: 80)
                    Image(systemName: mood.symbol)
                        .font(.system(size: 34))
                        .foregroundStyle(mood.symbolColor)
                }

                VStack(spacing: 10) {
                    Text(mood.rawValue)
                        .font(.title2.bold())
                        .foregroundStyle(Color("Stone950"))
                    Text(mood.response)
                        .font(.body)
                        .foregroundStyle(Color("Stone500"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            Button("Done", action: onDone)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color("Teal"))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
        }
        .background(Color("AppBackground").ignoresSafeArea())
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
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}
