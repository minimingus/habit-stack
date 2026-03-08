import SwiftUI

// MARK: - Main View

struct HabitsScorecardView: View {
    /// When non-nil, the view is embedded in onboarding — shows Continue/Skip instead of Done.
    var onContinue: (() -> Void)? = nil

    @State private var entries: [ScorecardEntry] = []
    @State private var newBehavior = ""
    @State private var replacingBehavior: String? = nil
    @State private var showReplaceWizard = false
    @FocusState private var inputFocused: Bool
    @Environment(\.dismiss) private var dismiss

    private let suggestions = [
        "Morning coffee", "Check phone", "Snooze alarm", "Brush teeth",
        "Breakfast", "Exercise", "Meditate", "Read", "Watch TV",
        "Scroll social media", "Take vitamins", "Journal",
        "Evening walk", "Drink water", "Late-night snacking",
    ]

    private var filteredSuggestions: [String] {
        let q = newBehavior.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return suggestions }
        return suggestions.filter { $0.localizedCaseInsensitiveContains(q) }
    }

    private var positiveCount: Int { entries.filter { $0.rating == .positive }.count }
    private var neutralCount: Int { entries.filter { $0.rating == .neutral }.count }
    private var negativeCount: Int { entries.filter { $0.rating == .negative }.count }
    private var unratedCount: Int { entries.filter { $0.rating == nil }.count }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // Framing text
                    Text("Notice what you actually do every day. Rate each behavior honestly.")
                        .font(.subheadline)
                        .foregroundStyle(Color("Stone500"))
                        .padding(.horizontal, 16)
                        .padding(.top, 4)

                    // Inline summary
                    if !entries.isEmpty {
                        HStack(spacing: 16) {
                            Label("\(positiveCount)", systemImage: "plus")
                                .font(.caption.bold()).foregroundStyle(Color("Teal"))
                            Label("\(neutralCount)", systemImage: "equal")
                                .font(.caption.bold()).foregroundStyle(Color("Stone500"))
                            Label("\(negativeCount)", systemImage: "minus")
                                .font(.caption.bold()).foregroundStyle(.red.opacity(0.7))
                            Spacer()
                            if unratedCount > 0 {
                                Text("\(unratedCount) unrated")
                                    .font(.caption).foregroundStyle(Color("Stone500").opacity(0.6))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                    }

                    // Suggestion chips
                    if !filteredSuggestions.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(filteredSuggestions, id: \.self) { suggestion in
                                    let alreadyAdded = entries.contains { $0.behavior == suggestion }
                                    Button {
                                        if !alreadyAdded {
                                            withAnimation {
                                                entries.append(ScorecardEntry(id: UUID(), behavior: suggestion, rating: nil))
                                            }
                                            ScorecardEntry.save(entries)
                                            HapticManager.impact(.light)
                                        }
                                    } label: {
                                        Text(suggestion)
                                            .font(.subheadline)
                                            .foregroundStyle(alreadyAdded ? Color("Stone500").opacity(0.5) : Color("Stone950"))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 7)
                                            .background(alreadyAdded ? Color("Stone100").opacity(0.5) : Color("Stone100"))
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(alreadyAdded)
                                }
                            }
                            .animation(.easeInOut(duration: 0.2), value: filteredSuggestions)
                            .padding(.horizontal, 16)
                        }
                    }

                    // Entry list
                    if !entries.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(entries) { entry in
                                ScorecardEntryRow(
                                    entry: entry,
                                    onRatingChanged: { setRating($0, for: entry.id) },
                                    onDelete: { deleteEntry(id: entry.id) },
                                    onReplace: { replacingBehavior = entry.behavior; showReplaceWizard = true }
                                )
                                if entry.id != entries.last?.id {
                                    Divider().padding(.leading, 16)
                                }
                            }
                        }
                        .background(Color("CardBackground"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 16)
                    }

                    // Empty prompt
                    if entries.isEmpty {
                        Text("Start with your morning — what's the first thing you actually do?")
                            .font(.subheadline)
                            .foregroundStyle(Color("Stone500").opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.top, 32)
                    }

                    Spacer(minLength: 80)
                }
                .padding(.vertical, 12)
            }
            .background(Color("AppBackground").ignoresSafeArea())
            .navigationTitle("Habits Scorecard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if let onContinue {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Skip") { onContinue() }
                            .foregroundStyle(Color("Stone500"))
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Continue →") { onContinue() }
                            .fontWeight(.semibold)
                            .foregroundStyle(Color("Teal"))
                    }
                } else {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { dismiss() }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                AddBehaviorField(text: $newBehavior, isFocused: $inputFocused, onAdd: addBehavior)
            }
        }
        .onAppear {
            entries = ScorecardEntry.load()
        }
        .sheet(isPresented: $showReplaceWizard, onDismiss: { replacingBehavior = nil }) {
            if let behavior = replacingBehavior {
                HabitWizardView(replacingBehavior: behavior) {
                    withAnimation {
                        entries.removeAll { $0.behavior == behavior }
                    }
                    ScorecardEntry.save(entries)
                }
            }
        }
    }

    // MARK: - Actions

    private func addBehavior() {
        let trimmed = newBehavior.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        withAnimation {
            entries.append(ScorecardEntry(id: UUID(), behavior: trimmed, rating: nil))
        }
        ScorecardEntry.save(entries)
        newBehavior = ""
        HapticManager.impact(.light)
    }

    private func setRating(_ rating: ScorecardEntry.Rating?, for id: UUID) {
        guard let idx = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[idx].rating = rating
        ScorecardEntry.save(entries)
        HapticManager.impact(.light)
    }

    private func deleteEntry(id: UUID) {
        withAnimation {
            entries.removeAll { $0.id == id }
        }
        ScorecardEntry.save(entries)
    }
}

// MARK: - Entry Row

private struct ScorecardEntryRow: View {
    let entry: ScorecardEntry
    let onRatingChanged: (ScorecardEntry.Rating?) -> Void
    let onDelete: () -> Void
    let onReplace: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(ratingColor.opacity(0.7))
                .frame(width: 3)
                .padding(.vertical, 6)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.behavior)
                    .font(.subheadline)
                    .foregroundStyle(Color("Stone950"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                if entry.rating == .negative {
                    Button { onReplace() } label: {
                        Label("Replace it", systemImage: "arrow.right")
                            .font(.caption.bold())
                            .foregroundStyle(Color("Teal"))
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            HStack(spacing: 3) {
                ForEach(ScorecardEntry.Rating.allCases, id: \.self) { rating in
                    Button {
                        withAnimation(.spring(duration: 0.2)) {
                            onRatingChanged(entry.rating == rating ? nil : rating)
                        }
                    } label: {
                        Text(rating.rawValue)
                            .font(.caption.bold())
                            .frame(width: 30, height: 30)
                            .background(entry.rating == rating ? buttonColor(rating) : Color("Stone100"))
                            .foregroundStyle(entry.rating == rating ? .white : Color("Stone500"))
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.trailing, 12)
        .padding(.vertical, 8)
        .background(rowTint)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var ratingColor: Color {
        switch entry.rating {
        case .positive: return Color("Teal")
        case .negative: return .red
        case .neutral: return Color("Stone500")
        case nil: return .clear
        }
    }

    private var rowTint: Color {
        switch entry.rating {
        case .positive: return Color("TealLight").opacity(0.25)
        case .negative: return Color.red.opacity(0.04)
        default: return Color("CardBackground")
        }
    }

    private func buttonColor(_ rating: ScorecardEntry.Rating) -> Color {
        switch rating {
        case .positive: return Color("Teal")
        case .neutral: return Color("Stone500")
        case .negative: return .red.opacity(0.7)
        }
    }
}

// MARK: - Add Behavior Field

private struct AddBehaviorField: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            TextField("Add a behavior…", text: $text)
                .focused(isFocused)
                .submitLabel(.done)
                .onSubmit(onAdd)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color("Stone100"))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(
                        text.trimmingCharacters(in: .whitespaces).isEmpty
                            ? Color("Stone500").opacity(0.4)
                            : Color("Teal")
                    )
            }
            .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
            .animation(.easeInOut(duration: 0.15), value: text.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial)
    }
}

