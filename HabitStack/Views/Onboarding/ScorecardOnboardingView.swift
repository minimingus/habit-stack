import SwiftUI

struct ScorecardOnboardingView: View {
    let onContinue: () -> Void

    private enum Step: Int {
        case intro, morning, afternoon, evening, night, rate
    }

    private struct Period {
        let step: Step
        let emoji: String
        let title: String
        let prompt: String
        let suggestions: [String]
    }

    private let periods: [Period] = [
        Period(step: .morning, emoji: "☀️", title: "Morning",
               prompt: "What do you actually do before noon?",
               suggestions: ["Snooze alarm", "Check phone in bed", "Brush teeth", "Coffee",
                             "Breakfast", "Exercise", "Meditate", "Shower", "Scroll social media"]),
        Period(step: .afternoon, emoji: "🌤", title: "Afternoon",
               prompt: "What do you actually do after lunch?",
               suggestions: ["Check phone", "Lunch", "Work / study", "Scroll social media",
                             "Coffee / snack", "Walk", "Watch YouTube", "Nap"]),
        Period(step: .evening, emoji: "🌆", title: "Evening",
               prompt: "What do you do in the evening?",
               suggestions: ["Dinner", "Watch TV / Netflix", "Scroll social media", "Read",
                             "Drink alcohol", "Exercise", "Call family", "Journal"]),
        Period(step: .night, emoji: "🌙", title: "Night",
               prompt: "How do you wind down?",
               suggestions: ["Check phone in bed", "Late-night snack", "Gaming",
                             "Read before sleep", "Skincare", "Take vitamins"]),
    ]

    @State private var currentStep: Step = .intro
    @State private var selected: Set<String> = []
    @State private var collectedBehaviors: [String] = []
    @State private var customText: String = ""
    @FocusState private var fieldFocused: Bool

    private var progressFraction: Double {
        if currentStep == .intro { return 0 }
        if currentStep == .rate { return 1.0 }
        return Double(currentStep.rawValue) / 5.0
    }

    var body: some View {
        ZStack {
            Color("AppBackground").ignoresSafeArea()
            switch currentStep {
            case .intro:
                introView
                    .transition(.opacity)
            case .rate:
                HabitsScorecardView(onContinue: onContinue)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            default:
                if let period = periods.first(where: { $0.step == currentStep }) {
                    periodView(period)
                        .id(currentStep)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentStep.rawValue)
    }

    // MARK: - Intro

    private var introView: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 24) {
                Text("📋")
                    .font(.system(size: 64))
                VStack(spacing: 12) {
                    Text("What does your day\nactually look like?")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color("Stone950"))
                        .multilineTextAlignment(.center)
                    Text("Most habits are invisible. Before building new ones,\nlet's see what you actually do each day.")
                        .font(.subheadline)
                        .foregroundStyle(Color("Stone500"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
            }
            .padding(.horizontal, 32)
            Spacer()
            Button {
                withAnimation { currentStep = .morning }
            } label: {
                Text("Map My Day →")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("Teal"))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    // MARK: - Period step

    private func periodView(_ period: Period) -> some View {
        VStack(spacing: 0) {
            progressBar
                .padding(.horizontal, 24)
                .padding(.top, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(period.emoji)
                            .font(.system(size: 44))
                        Text(period.title)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Color("Stone950"))
                        Text(period.prompt)
                            .font(.subheadline)
                            .foregroundStyle(Color("Stone500"))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 130), spacing: 10)],
                        spacing: 10
                    ) {
                        ForEach(period.suggestions, id: \.self) { suggestion in
                            chipButton(suggestion)
                        }
                    }
                    .padding(.horizontal, 24)

                    HStack(spacing: 10) {
                        TextField("Add your own…", text: $customText)
                            .focused($fieldFocused)
                            .submitLabel(.done)
                            .onSubmit { addCustom() }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color("Stone100"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        Button(action: addCustom) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(
                                    customText.trimmingCharacters(in: .whitespaces).isEmpty
                                        ? Color("Stone500").opacity(0.4) : Color("Teal")
                                )
                        }
                        .disabled(customText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: 100)
                }
            }

            bottomBar(isLast: currentStep == .night)
        }
    }

    @ViewBuilder
    private func chipButton(_ suggestion: String) -> some View {
        let isOn = selected.contains(suggestion)
        Button {
            withAnimation(.spring(duration: 0.2)) {
                if isOn { selected.remove(suggestion) }
                else { selected.insert(suggestion) }
            }
            HapticManager.impact(.light)
        } label: {
            Text(suggestion)
                .font(.subheadline)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(isOn ? Color("Teal") : Color("Stone100"))
                .foregroundStyle(isOn ? .white : Color("Stone950"))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(isOn ? Color.clear : Color.white.opacity(0.06), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color("Stone100"))
                    .frame(height: 4)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color("Teal"))
                    .frame(width: geo.size.width * progressFraction, height: 4)
                    .animation(.spring(duration: 0.4), value: progressFraction)
            }
        }
        .frame(height: 4)
    }

    private func bottomBar(isLast: Bool) -> some View {
        HStack {
            Button("Skip") { advance() }
                .foregroundStyle(Color("Stone500"))
            Spacer()
            Button { advance() } label: {
                Text(isLast ? "Done →" : "Next →")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(Color("Teal"))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
        .padding(.top, 12)
        .background(.regularMaterial)
    }

    // MARK: - Helpers

    private func advance() {
        fieldFocused = false
        addCustom()
        collectedBehaviors.append(contentsOf: selected)
        selected = []
        if currentStep == .night {
            commitEntries()
            withAnimation { currentStep = .rate }
        } else {
            let next = Step(rawValue: currentStep.rawValue + 1) ?? .rate
            withAnimation { currentStep = next }
        }
    }

    private func addCustom() {
        let trimmed = customText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        selected.insert(trimmed)
        customText = ""
        HapticManager.impact(.light)
    }

    private func commitEntries() {
        guard !collectedBehaviors.isEmpty else { return }
        var existing = ScorecardEntry.load()
        let existingBehaviors = Set(existing.map { $0.behavior })
        let newEntries = collectedBehaviors
            .filter { !existingBehaviors.contains($0) }
            .map { ScorecardEntry(id: UUID(), behavior: $0, rating: nil) }
        existing = newEntries + existing
        ScorecardEntry.save(existing)
    }
}
