import SwiftUI

// MARK: - Main View

struct HabitsScorecardView: View {
    @State private var entries: [ScorecardEntry] = []
    @State private var newBehavior = ""
    @FocusState private var inputFocused: Bool
    @Environment(\.dismiss) private var dismiss

    private var positiveCount: Int { entries.filter { $0.rating == .positive }.count }
    private var neutralCount: Int { entries.filter { $0.rating == .neutral }.count }
    private var negativeCount: Int { entries.filter { $0.rating == .negative }.count }
    private var unratedCount: Int { entries.filter { $0.rating == nil }.count }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    ScorecardIntroCard()

                    if !entries.isEmpty {
                        ScorecardSummaryBar(
                            positive: positiveCount,
                            neutral: neutralCount,
                            negative: negativeCount,
                            unrated: unratedCount
                        )
                        .padding(.horizontal, 16)
                    }

                    if entries.isEmpty {
                        ScorecardEmptyState()
                            .padding(.horizontal, 16)
                    } else {
                        VStack(spacing: 1) {
                            ForEach(entries) { entry in
                                ScorecardEntryRow(
                                    entry: entry,
                                    onRatingChanged: { newRating in
                                        setRating(newRating, for: entry.id)
                                    },
                                    onDelete: {
                                        deleteEntry(id: entry.id)
                                    }
                                )
                                if entry.id != entries.last?.id {
                                    Divider().padding(.leading, 16)
                                }
                            }
                        }
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                        .padding(.horizontal, 16)
                    }

                    ScorecardRatingGuide()
                        .padding(.horizontal, 16)

                    Spacer(minLength: 80)
                }
                .padding(.vertical, 16)
            }
            .background(Color("Stone100").ignoresSafeArea())
            .navigationTitle("Habits Scorecard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                AddBehaviorField(text: $newBehavior, isFocused: $inputFocused, onAdd: addBehavior)
            }
        }
        .onAppear { entries = ScorecardEntry.load() }
    }

    // MARK: - Actions

    private func addBehavior() {
        let trimmed = newBehavior.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        entries.append(ScorecardEntry(id: UUID(), behavior: trimmed, rating: nil))
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
        entries.removeAll { $0.id == id }
        ScorecardEntry.save(entries)
    }
}

// MARK: - Intro Card (book-faithful framing)

private struct ScorecardIntroCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "hand.point.right.fill")
                    .font(.title3)
                    .foregroundStyle(Color("Teal"))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Habits Scorecard")
                        .font(.headline)
                        .foregroundStyle(Color("Stone950"))
                    Text("Make the unconscious conscious")
                        .font(.caption)
                        .foregroundStyle(Color("Stone500"))
                }
            }

            Text("Japanese train conductors point at every signal and call it aloud — reducing errors by 85%. Apply the same idea to your daily behaviors: name them, see them clearly.")
                .font(.subheadline)
                .foregroundStyle(Color("Stone500"))

            Divider()

            Text("List every behavior you already do — the good, bad, and mundane. Rate each one. There's no need to change anything yet. **The goal is simply to notice what is actually going on.**")
                .font(.subheadline)
                .foregroundStyle(Color("Stone500"))
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        .padding(.horizontal, 16)
    }
}

// MARK: - Summary Bar

private struct ScorecardSummaryBar: View {
    let positive: Int
    let neutral: Int
    let negative: Int
    let unrated: Int

    var body: some View {
        HStack(spacing: 0) {
            SummaryCell(value: positive, symbol: "+", color: Color("Teal"), label: "positive")
            Divider().frame(height: 40)
            SummaryCell(value: neutral, symbol: "=", color: Color("Stone500"), label: "neutral")
            Divider().frame(height: 40)
            SummaryCell(value: negative, symbol: "–", color: .red.opacity(0.7), label: "working against")
            if unrated > 0 {
                Divider().frame(height: 40)
                SummaryCell(value: unrated, symbol: "?", color: Color("Stone500").opacity(0.5), label: "unrated")
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

private struct SummaryCell: View {
    let value: Int
    let symbol: String
    let color: Color
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                Text(symbol)
                    .font(.headline.bold())
                    .foregroundStyle(color)
                Text("\(value)")
                    .font(.headline.bold())
                    .foregroundStyle(Color("Stone950"))
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color("Stone500"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }
}

// MARK: - Entry Row

private struct ScorecardEntryRow: View {
    let entry: ScorecardEntry
    let onRatingChanged: (ScorecardEntry.Rating?) -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Rating indicator strip
            Rectangle()
                .fill(ratingColor.opacity(0.6))
                .frame(width: 4)
                .padding(.vertical, 4)

            // Behavior label
            Text(entry.behavior)
                .font(.body)
                .foregroundStyle(Color("Stone950"))
                .frame(maxWidth: .infinity, alignment: .leading)

            // + = – toggle buttons
            HStack(spacing: 4) {
                ForEach(ScorecardEntry.Rating.allCases, id: \.self) { rating in
                    Button {
                        withAnimation(.spring(duration: 0.2)) {
                            onRatingChanged(entry.rating == rating ? nil : rating)
                        }
                    } label: {
                        Text(rating.rawValue)
                            .font(.subheadline.bold())
                            .frame(width: 34, height: 34)
                            .background(entry.rating == rating ? buttonColor(rating) : Color("Stone100"))
                            .foregroundStyle(entry.rating == rating ? .white : Color("Stone500"))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.leading, 0)
        .padding(.trailing, 16)
        .padding(.vertical, 10)
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
        case nil: return Color.clear
        }
    }

    private var rowTint: Color {
        switch entry.rating {
        case .positive: return Color("TealLight").opacity(0.25)
        case .negative: return Color.red.opacity(0.04)
        default: return Color.white
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

// MARK: - Rating Guide

private struct ScorecardRatingGuide: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How to rate each behavior")
                .font(.caption.bold())
                .foregroundStyle(Color("Stone500"))
                .textCase(.uppercase)
                .kerning(0.5)

            VStack(alignment: .leading, spacing: 6) {
                GuideRow(symbol: "+", color: Color("Teal"), text: "Effective in the long run — casts a vote for who you want to become")
                GuideRow(symbol: "=", color: Color("Stone500"), text: "Neutral — neither helps nor hurts")
                GuideRow(symbol: "–", color: .red.opacity(0.7), text: "Working against you — net negative over time")
            }

            Divider()

            Text("Not sure? Ask yourself:")
                .font(.caption.bold())
                .foregroundStyle(Color("Stone500"))

            Text("\"Does this behavior help me become the type of person I wish to be? Does this habit cast a vote **for** or **against** my desired identity?\"")
                .font(.subheadline)
                .foregroundStyle(Color("Stone500"))
                .italic()

            Text("Observe without judgment. There are no objectively good or bad habits — only effective or ineffective ones relative to your goals.")
                .font(.caption)
                .foregroundStyle(Color("Stone500").opacity(0.8))
                .padding(.top, 2)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

private struct GuideRow: View {
    let symbol: String
    let color: Color
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(symbol)
                .font(.subheadline.bold())
                .frame(width: 28, height: 28)
                .background(color)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 7))
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color("Stone950"))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Empty State

private struct ScorecardEmptyState: View {
    private let examples = [
        "Wake up", "Turn off alarm", "Check my phone",
        "Make coffee", "Brush my teeth", "Check social media",
        "Read the news", "Exercise", "Scroll Instagram"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Start with what you already do — the mundane, automatic behaviors you don't even think about.")
                .font(.subheadline)
                .foregroundStyle(Color("Stone500"))

            Text("For example:")
                .font(.caption.bold())
                .foregroundStyle(Color("Stone500"))

            FlowLayout(spacing: 6) {
                ForEach(examples, id: \.self) { example in
                    Text(example)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color("Stone100"))
                        .foregroundStyle(Color("Stone500"))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

// MARK: - Add Behavior Field

private struct AddBehaviorField: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            TextField("Add a behavior (e.g. Check my phone)", text: $text)
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

// MARK: - FlowLayout (wrapping chip rows)

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let width = proposal.width ?? .infinity
        var height: CGFloat = 0
        var x: CGFloat = 0
        var rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                height += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        height += rowHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
