import SwiftUI

private struct LawScore {
    let title: String
    let icon: String
    let tip: String
    let count: Int
    let total: Int
    var fraction: Double { total == 0 ? 0 : Double(count) / Double(total) }
}

struct FourLawsView: View {
    @State private var habits: [Habit] = []
    @State private var identityVotes: [IdentityVote] = []
    @State private var isLoading = false
    @State private var showScorecard = false

    private var lawScores: [LawScore] {
        let n = habits.count
        return [
            LawScore(
                title: "Make it Obvious",
                icon: "eye",
                tip: "Add a cue or anchor habit to each habit",
                count: habits.filter { !($0.cue ?? "").isEmpty }.count,
                total: n
            ),
            LawScore(
                title: "Make it Attractive",
                icon: "heart",
                tip: "Write why each habit matters to you",
                count: habits.filter { !($0.craving ?? "").isEmpty }.count,
                total: n
            ),
            LawScore(
                title: "Make it Easy",
                icon: "bolt",
                tip: "Set a 2-minute version for each habit",
                count: habits.filter { !($0.tinyVersion ?? "").isEmpty }.count,
                total: n
            ),
            LawScore(
                title: "Make it Satisfying",
                icon: "star",
                tip: "Define an immediate reward for each habit",
                count: habits.filter { !($0.reward ?? "").isEmpty }.count,
                total: n
            ),
        ]
    }

    private var topIdentity: String? {
        let grouped = Dictionary(grouping: identityVotes, by: { $0.identityStatement })
        return grouped.max(by: { $0.value.count < $1.value.count })?.key
    }

    private var identityGroups: [(String, Int)] {
        let grouped = Dictionary(grouping: identityVotes, by: { $0.identityStatement })
        return grouped.map { ($0.key, $0.value.count) }
            .sorted { $0.1 > $1.1 }
            .prefix(3)
            .map { $0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // MARK: Habits Scorecard entry point
                    Button { showScorecard = true } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "hand.point.right.fill")
                                .font(.title2)
                                .foregroundStyle(Color("Teal"))
                                .frame(width: 40)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Habits Scorecard")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color("Stone950"))
                                Text("Point & call your daily behaviors — make the unconscious conscious")
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
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)

                    // MARK: Identity Hero
                    IdentityHeroCard(statement: topIdentity)
                        .padding(.horizontal, 16)

                    // MARK: System Health
                    if !habits.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Habit System Health")
                                    .font(.headline)
                                    .foregroundStyle(Color("Stone950"))
                                Text("How well are you applying the Four Laws?")
                                    .font(.caption)
                                    .foregroundStyle(Color("Stone500"))
                            }
                            .padding(.horizontal, 16)

                            VStack(spacing: 0) {
                                ForEach(Array(lawScores.enumerated()), id: \.offset) { index, law in
                                    LawScoreRow(law: law)
                                    if index < lawScores.count - 1 {
                                        Divider().padding(.leading, 52)
                                    }
                                }
                            }
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                            .padding(.horizontal, 16)
                        }
                    }

                    // MARK: Identity Votes
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("My Identity Votes")
                                .font(.headline)
                                .foregroundStyle(Color("Stone950"))
                            Text("Each completed habit is a vote for who you're becoming.")
                                .font(.caption)
                                .foregroundStyle(Color("Stone500"))
                        }
                        .padding(.horizontal, 16)

                        if identityVotes.isEmpty {
                            IdentityEmptyState()
                                .padding(.horizontal, 16)
                        } else {
                            ForEach(identityGroups, id: \.0) { statement, count in
                                IdentityVoteView(statement: statement, voteCount: count) {
                                    await castVote(for: statement)
                                }
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
        }
    }

    private func load() async {
        guard let userId = try? await supabase.auth.session.user.id else { return }
        isLoading = true
        habits = (try? await supabase
            .from("habits")
            .select()
            .eq("user_id", value: userId.uuidString)
            .is("archived_at", value: nil)
            .execute()
            .value) ?? []
        identityVotes = (try? await supabase
            .from("identity_votes")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value) ?? []
        isLoading = false
    }

    private func castVote(for statement: String) async {
        guard let userId = try? await supabase.auth.session.user.id else { return }
        let vote = IdentityVote(
            id: UUID(),
            habitId: habits.first?.id ?? UUID(),
            userId: userId,
            identityStatement: statement,
            votedAt: Date()
        )
        _ = try? await supabase.from("identity_votes").insert(vote).execute()
        HapticManager.impact(.light)
        await load()
    }
}

// MARK: - Identity Hero Card

private struct IdentityHeroCard: View {
    let statement: String?

    var body: some View {
        VStack(spacing: 12) {
            if let statement {
                VStack(spacing: 8) {
                    Text("You are becoming")
                        .font(.caption)
                        .foregroundStyle(Color("Teal"))
                        .textCase(.uppercase)
                        .kerning(0.8)

                    Text("someone who \(statement.lowercased())")
                        .font(.title3.bold())
                        .foregroundStyle(Color("Stone950"))
                        .multilineTextAlignment(.center)

                    Text("Keep showing up. Identity is built one rep at a time.")
                        .font(.caption)
                        .foregroundStyle(Color("Stone500"))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(
                    LinearGradient(
                        colors: [Color("TealLight"), Color("TealLight").opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color("Teal").opacity(0.2), lineWidth: 1)
                )
            } else {
                VStack(spacing: 8) {
                    Text("Who are you becoming?")
                        .font(.title3.bold())
                        .foregroundStyle(Color("Stone950"))
                    Text("Complete habits to cast identity votes. Every check-in says: this is the kind of person I am.")
                        .font(.subheadline)
                        .foregroundStyle(Color("Stone500"))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
            }
        }
    }
}

// MARK: - Law Score Row

private struct LawScoreRow: View {
    let law: LawScore

    private var scoreColor: Color {
        if law.total == 0 { return Color("Stone500") }
        if law.fraction >= 0.75 { return Color("Teal") }
        if law.fraction >= 0.4 { return .orange }
        return .red.opacity(0.7)
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: law.icon)
                .font(.system(size: 16))
                .foregroundStyle(scoreColor)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(law.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color("Stone950"))
                    Spacer()
                    Text("\(law.count)/\(law.total)")
                        .font(.caption.bold())
                        .foregroundStyle(scoreColor)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color("Stone100"))
                            .frame(height: 5)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(scoreColor)
                            .frame(width: geo.size.width * law.fraction, height: 5)
                            .animation(.spring(duration: 0.6), value: law.fraction)
                    }
                }
                .frame(height: 5)

                if law.total > 0 && law.fraction < 0.5 {
                    Text(law.tip)
                        .font(.caption2)
                        .foregroundStyle(Color("Stone500"))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Identity Empty State

private struct IdentityEmptyState: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 40))
                .foregroundStyle(Color("Teal").opacity(0.5))
            Text("No identity votes yet")
                .font(.subheadline.bold())
                .foregroundStyle(Color("Stone950"))
            Text("Go to Today and complete a habit.\nEach one adds a vote here.")
                .font(.caption)
                .foregroundStyle(Color("Stone500"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
    }
}

// MARK: - Identity Vote View

struct IdentityVoteView: View {
    let statement: String
    let voteCount: Int
    let onVote: () async -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(statement)
                    .font(.subheadline)
                    .foregroundStyle(Color("Stone950"))
                Text("\(voteCount) vote\(voteCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(Color("Stone500"))
            }
            Spacer()
            Button {
                Task { await onVote() }
            } label: {
                Image(systemName: "hand.thumbsup.fill")
                    .foregroundStyle(Color("Teal"))
                    .padding(8)
                    .background(Color("TealLight"))
                    .clipShape(Circle())
            }
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}
