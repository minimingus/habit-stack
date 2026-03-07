import SwiftUI

struct FourLawsView: View {
    @State private var habits: [Habit] = []
    @State private var allVotes: [IdentityVote] = []
    @State private var showScorecard = false
    @State private var editingHabit: Habit? = nil
    @State private var expandedLaw: String? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // MARK: 1. Identity Statement — front and centre
                    IdentityCarousel(
                        habits: habits,
                        votes: allVotes,
                        onHabitTap: { habit in editingHabit = habit }
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
                        .background(Color("CardBackground"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
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
            .background(Color("AppBackground").ignoresSafeArea())
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
        allVotes = loadedVotes
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
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Identity Carousel

private struct IdentityCarousel: View {
    let habits: [Habit]
    let votes: [IdentityVote]
    let onHabitTap: (Habit) -> Void

    struct IdentityGroup: Identifiable {
        let id: String
        let statement: String
        let habits: [Habit]
        let evidenceCount: Int
    }

    private var groups: [IdentityGroup] {
        let withCraving = habits.filter { !($0.craving ?? "").isEmpty }
        let grouped = Dictionary(grouping: withCraving, by: { $0.craving! })
        return grouped.map { key, value in
            let count = votes.filter { $0.identityStatement == key }.count
            return IdentityGroup(id: key, statement: key, habits: value, evidenceCount: count)
        }
        .sorted { $0.evidenceCount > $1.evidenceCount }
    }

    var body: some View {
        if groups.isEmpty {
            emptyCard
        } else if groups.count == 1 {
            IdentityCard(group: groups[0], onHabitTap: onHabitTap)
        } else {
            TabView {
                ForEach(groups) { group in
                    IdentityCard(group: group, onHabitTap: onHabitTap)
                        .padding(.bottom, 24)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .frame(height: 240)
        }
    }

    private var emptyCard: some View {
        VStack(spacing: 12) {
            Text("I am becoming")
                .font(.caption.bold())
                .foregroundStyle(Color("Teal"))
                .textCase(.uppercase)
                .kerning(0.8)
            Text("Who do you want to become?")
                .font(.title3.bold())
                .foregroundStyle(Color("Stone500"))
                .multilineTextAlignment(.center)
            Text("Add a \"Why\" to any habit to build your identity here.")
                .font(.caption)
                .foregroundStyle(Color("Stone500").opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Identity Card

private struct IdentityCard: View {
    let group: IdentityCarousel.IdentityGroup
    let onHabitTap: (Habit) -> Void

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("I am becoming")
                    .font(.caption.bold())
                    .foregroundStyle(Color("Teal"))
                    .textCase(.uppercase)
                    .kerning(0.8)
                Text("someone who \(group.statement.lowercased())")
                    .font(.title3.bold())
                    .foregroundStyle(Color("Stone950"))
                    .multilineTextAlignment(.center)
            }

            // Habit chips
            HStack(spacing: 8) {
                ForEach(group.habits) { habit in
                    Button { onHabitTap(habit) } label: {
                        Text("\(habit.emoji) \(habit.name)")
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color("CardBackground").opacity(0.7))
                            .foregroundStyle(Color("Stone950"))
                            .clipShape(Capsule())
                            .overlay(Capsule().strokeBorder(Color("Teal").opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }

            if group.evidenceCount > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color("Teal"))
                    Text("\(group.evidenceCount) completion\(group.evidenceCount == 1 ? "" : "s") as evidence")
                        .font(.subheadline)
                        .foregroundStyle(Color("Stone950"))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color("TealLight"))
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color("TealLight"), Color("TealLight").opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
