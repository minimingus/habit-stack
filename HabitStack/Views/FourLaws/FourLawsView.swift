import SwiftUI

struct FourLawsView: View {
    @State private var habits: [Habit] = []
    @State private var totalVotes: Int = 0
    @State private var showScorecard = false
    @State private var editingHabit: Habit? = nil
    @State private var showEditIdentity = false
    @State private var identityStatement: String = ""
    @State private var expandedLaw: String? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // MARK: 1. Identity Statement — front and centre
                    IdentityHeroCard(
                        statement: identityStatement,
                        votes: totalVotes,
                        onEdit: { showEditIdentity = true }
                    )
                    .padding(.horizontal, 16)

                    // MARK: 2. Habits Scorecard — prominent action
                    Button { showScorecard = true } label: {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color("TealLight"))
                                    .frame(width: 48, height: 48)
                                Image(systemName: "hand.point.right.fill")
                                    .font(.title3)
                                    .foregroundStyle(Color("Teal"))
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Habits Scorecard")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color("Stone950"))
                                Text("List your daily behaviors and rate them +/=/–. Make the unconscious conscious.")
                                    .font(.caption)
                                    .foregroundStyle(Color("Stone500"))
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.bold())
                                .foregroundStyle(Color("Stone500"))
                        }
                        .padding(16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)

                    // MARK: 3. System Health — each law interactive
                    if !habits.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Habit System Health")
                                    .font(.headline)
                                Text("Tap a law to see which habits need attention.")
                                    .font(.caption)
                                    .foregroundStyle(Color("Stone500"))
                            }
                            .padding(.horizontal, 16)

                            ForEach(lawCards, id: \.title) { card in
                                LawCard(
                                    card: card,
                                    isExpanded: expandedLaw == card.title,
                                    onToggle: {
                                        withAnimation(.spring(duration: 0.3)) {
                                            expandedLaw = expandedLaw == card.title ? nil : card.title
                                        }
                                    },
                                    onEdit: { habit in editingHabit = habit }
                                )
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color("Stone100").ignoresSafeArea())
            .navigationTitle("Identity")
            .task { await load() }
            .refreshable { await load() }
            .sheet(isPresented: $showScorecard) {
                HabitsScorecardView()
            }
            .sheet(item: $editingHabit) { habit in
                HabitWizardView(editingHabit: habit) {
                    Task { await load() }
                }
            }
            .sheet(isPresented: $showEditIdentity) {
                EditIdentitySheet(statement: $identityStatement)
            }
        }
    }

    // MARK: - Law Cards Data

    private var lawCards: [LawCardData] {
        [
            LawCardData(
                title: "Make it Obvious",
                icon: "eye.fill",
                description: "Every habit needs a clear cue — when and where it happens.",
                missingHabits: habits.filter { ($0.cue ?? "").isEmpty },
                missingLabel: "No cue set",
                allHabits: habits
            ),
            LawCardData(
                title: "Make it Attractive",
                icon: "heart.fill",
                description: "Link habits to your identity — why this matters to you.",
                missingHabits: habits.filter { ($0.craving ?? "").isEmpty },
                missingLabel: "No identity link",
                allHabits: habits
            ),
            LawCardData(
                title: "Make it Easy",
                icon: "bolt.fill",
                description: "Scale each habit down to a 2-minute version to remove friction.",
                missingHabits: habits.filter { ($0.tinyVersion ?? "").isEmpty },
                missingLabel: "No 2-min version",
                allHabits: habits
            ),
            LawCardData(
                title: "Make it Satisfying",
                icon: "star.fill",
                description: "Define an immediate reward so your brain wants to repeat it.",
                missingHabits: habits.filter { ($0.reward ?? "").isEmpty },
                missingLabel: "No reward defined",
                allHabits: habits
            ),
        ]
    }

    // MARK: - Load

    private func load() async {
        guard let userId = try? await supabase.auth.session.user.id else { return }

        async let habitsResult: [Habit] = (try? await supabase
            .from("habits")
            .select()
            .eq("user_id", value: userId.uuidString)
            .is("archived_at", value: nil)
            .execute()
            .value) ?? []

        async let votesResult: [IdentityVote] = (try? await supabase
            .from("identity_votes")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value) ?? []

        let (loadedHabits, loadedVotes) = await (habitsResult, votesResult)
        habits = loadedHabits
        totalVotes = loadedVotes.count

        // Identity statement: onboarding entry takes priority, fall back to top vote
        if let saved = UserDefaults.standard.string(forKey: "onboardingIdentityStatement"), !saved.isEmpty {
            identityStatement = saved
        } else {
            let grouped = Dictionary(grouping: loadedVotes, by: { $0.identityStatement })
            identityStatement = grouped.max(by: { $0.value.count < $1.value.count })?.key ?? ""
        }
    }
}

// MARK: - Law Card Data

private struct LawCardData {
    let title: String
    let icon: String
    let description: String
    let missingHabits: [Habit]
    let missingLabel: String
    let allHabits: [Habit]

    var fraction: Double {
        allHabits.isEmpty ? 1 : Double(allHabits.count - missingHabits.count) / Double(allHabits.count)
    }

    var scoreColor: Color {
        if fraction >= 1.0 { return Color("Teal") }
        if fraction >= 0.5 { return .orange }
        return .red.opacity(0.7)
    }
}

// MARK: - Law Card View

private struct LawCard: View {
    let card: LawCardData
    let isExpanded: Bool
    let onToggle: () -> Void
    let onEdit: (Habit) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header — always visible
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    Image(systemName: card.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(card.scoreColor)
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(card.title)
                                .font(.subheadline.bold())
                                .foregroundStyle(Color("Stone950"))
                            Spacer()
                            Text("\(card.allHabits.count - card.missingHabits.count)/\(card.allHabits.count)")
                                .font(.caption.bold())
                                .foregroundStyle(card.scoreColor)
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color("Stone100"))
                                    .frame(height: 5)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(card.scoreColor)
                                    .frame(width: geo.size.width * card.fraction, height: 5)
                                    .animation(.spring(duration: 0.5), value: card.fraction)
                            }
                        }
                        .frame(height: 5)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.bold())
                        .foregroundStyle(Color("Stone500"))
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            // Expanded — missing habits with Fix buttons
            if isExpanded {
                Divider().padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 0) {
                    Text(card.description)
                        .font(.caption)
                        .foregroundStyle(Color("Stone500"))
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 8)

                    if card.missingHabits.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color("Teal"))
                            Text("All habits have this covered.")
                                .font(.subheadline)
                                .foregroundStyle(Color("Stone950"))
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 14)
                    } else {
                        ForEach(card.missingHabits) { habit in
                            HStack {
                                Text(habit.emoji)
                                Text(habit.name)
                                    .font(.subheadline)
                                    .foregroundStyle(Color("Stone950"))
                                Spacer()
                                Button {
                                    onEdit(habit)
                                } label: {
                                    Text("Fix →")
                                        .font(.caption.bold())
                                        .foregroundStyle(Color("Teal"))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color("TealLight"))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)

                            if habit.id != card.missingHabits.last?.id {
                                Divider().padding(.leading, 16)
                            }
                        }
                        .padding(.bottom, 8)
                    }
                }
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
    }
}

// MARK: - Identity Hero Card

private struct IdentityHeroCard: View {
    let statement: String
    let votes: Int
    let onEdit: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 10) {
                Text("I am becoming")
                    .font(.caption.bold())
                    .foregroundStyle(Color("Teal"))
                    .textCase(.uppercase)
                    .kerning(0.8)

                if statement.isEmpty {
                    Text("Who do you want to become?")
                        .font(.title3.bold())
                        .foregroundStyle(Color("Stone500"))
                        .multilineTextAlignment(.center)
                } else {
                    Text("someone who \(statement.lowercased())")
                        .font(.title3.bold())
                        .foregroundStyle(Color("Stone950"))
                        .multilineTextAlignment(.center)
                }
            }

            // Vote evidence
            if votes > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color("Teal"))
                    Text("\(votes) habit completion\(votes == 1 ? "" : "s") as evidence")
                        .font(.subheadline)
                        .foregroundStyle(Color("Stone950"))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color("TealLight"))
                .clipShape(Capsule())
            }

            Button(action: onEdit) {
                Label(statement.isEmpty ? "Set your identity" : "Edit", systemImage: "pencil")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color("Teal"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.8))
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(Color("Teal").opacity(0.3), lineWidth: 1))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            statement.isEmpty
                ? AnyShapeStyle(Color.white)
                : AnyShapeStyle(LinearGradient(
                    colors: [Color("TealLight"), Color("TealLight").opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }
}

// MARK: - Edit Identity Sheet

private struct EditIdentitySheet: View {
    @Binding var statement: String
    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""

    private let suggestions = [
        "reads every day", "exercises consistently", "sleeps 8 hours",
        "eats healthy", "meditates daily", "journals regularly",
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("I am someone who…")
                            .font(.caption.bold())
                            .foregroundStyle(Color("Stone500"))
                            .textCase(.uppercase)
                            .kerning(0.5)

                        TextField("e.g. exercises consistently", text: $draft)
                            .padding(14)
                            .background(Color("Stone100"))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 20)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Suggestions")
                            .font(.caption)
                            .foregroundStyle(Color("Stone500"))
                            .padding(.horizontal, 20)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(suggestions, id: \.self) { s in
                                    Button { draft = s } label: {
                                        Text(s)
                                            .font(.subheadline)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(draft == s ? Color("Teal") : Color("Stone100"))
                                            .foregroundStyle(draft == s ? Color.white : Color("Stone950"))
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.top, 16)
            }
            .background(Color("Stone100").ignoresSafeArea())
            .navigationTitle("Your Identity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = draft.trimmingCharacters(in: .whitespaces)
                        if !trimmed.isEmpty {
                            statement = trimmed
                            UserDefaults.standard.set(trimmed, forKey: "onboardingIdentityStatement")
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { draft = statement }
        }
    }
}
