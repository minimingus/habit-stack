import SwiftUI

struct FourLawsView: View {
    @State private var habits: [Habit] = []
    @State private var identityVotes: [IdentityVote] = []
    @State private var isLoading = false

    private let laws: [(title: String, subtitle: String, timeOfDay: [Habit.TimeOfDay]?)] = [
        ("Make it Obvious", "Design your environment. Use cues and habit stacking.", nil),
        ("Make it Attractive", "Bundle habits with things you enjoy.", nil),
        ("Make it Easy", "Reduce friction with the 2-minute rule.", nil),
        ("Make it Satisfying", "Reward yourself immediately.", nil)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(laws.indices, id: \.self) { i in
                        LawCard(
                            title: laws[i].title,
                            subtitle: laws[i].subtitle,
                            habits: habitsForLaw(i)
                        )
                        .padding(.horizontal, 16)
                    }

                    // Identity votes
                    VStack(alignment: .leading, spacing: 12) {
                        Text("My Identity")
                            .font(.headline)
                            .padding(.horizontal, 16)

                        Text("I am the type of person who...")
                            .font(.subheadline)
                            .foregroundStyle(Color("Stone500"))
                            .padding(.horizontal, 16)

                        if identityVotes.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "person.fill.checkmark")
                                    .font(.system(size: 36))
                                    .foregroundStyle(Color("Teal").opacity(0.6))
                                Text("Complete habits to build your identity.")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color("Stone950"))
                                Text("Each check-in is a vote for who you're becoming.\nStart by completing a habit in the Today tab.")
                                    .font(.caption)
                                    .foregroundStyle(Color("Stone500"))
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                            .padding(.horizontal, 16)
                        } else {
                            let grouped = Dictionary(grouping: identityVotes, by: { $0.identityStatement })
                            let top3 = grouped.sorted { $0.value.count > $1.value.count }.prefix(3)

                            ForEach(top3, id: \.key) { statement, votes in
                                IdentityVoteView(statement: statement, voteCount: votes.count) {
                                    await castVote(for: statement)
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            .navigationTitle("Four Laws")
            .task { await load() }
        }
    }

    private func habitsForLaw(_ index: Int) -> [Habit] {
        switch index {
        case 0: return habits.filter { $0.cue != nil && !($0.cue?.isEmpty ?? true) }
        case 1: return habits.filter { $0.craving != nil && !($0.craving?.isEmpty ?? true) }
        case 2: return habits.filter { $0.tinyVersion != nil && !($0.tinyVersion?.isEmpty ?? true) }
        case 3: return habits.filter { $0.reward != nil && !($0.reward?.isEmpty ?? true) }
        default: return []
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

struct LawCard: View {
    let title: String
    let subtitle: String
    let habits: [Habit]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color("Stone950"))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color("Stone500"))
            }

            if habits.isEmpty {
                Text("No habits using this law yet")
                    .font(.caption)
                    .foregroundStyle(Color("Stone500").opacity(0.7))
                    .italic()
            } else {
                ForEach(habits) { habit in
                    HStack(spacing: 6) {
                        Text(habit.emoji)
                        Text(habit.name)
                            .font(.subheadline)
                    }
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
