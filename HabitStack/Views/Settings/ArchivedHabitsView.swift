import SwiftUI

@MainActor
@Observable final class ArchivedHabitsViewModel {
    var habits: [Habit] = []
    var isLoading = false
    var error: String?

    func load() async {
        isLoading = true
        defer { isLoading = false }
        guard let userId = try? await supabase.auth.session.user.id else { return }
        habits = (try? await HabitService.shared.fetchArchivedHabits(userId: userId)) ?? []
    }

    func restore(_ habit: Habit) async {
        do {
            try await HabitService.shared.restoreHabit(habit.id)
            habits.removeAll { $0.id == habit.id }
            HapticManager.impact(.light)
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct ArchivedHabitsView: View {
    @State private var viewModel = ArchivedHabitsViewModel()

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.habits.isEmpty {
                    ContentUnavailableView(
                        "No Archived Habits",
                        systemImage: "archivebox",
                        description: Text("Habits you archive will appear here.")
                    )
                } else {
                    List {
                        ForEach(viewModel.habits) { habit in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color(hex: habit.color))
                                    .frame(width: 12, height: 12)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(habit.name)
                                        .foregroundStyle(.primary)

                                    if let archivedAt = habit.archivedAt {
                                        Text(Self.dateFormatter.string(from: archivedAt))
                                            .font(.caption)
                                            .foregroundStyle(Color("Stone500"))
                                    }
                                }

                                Spacer()
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button {
                                    Task { await viewModel.restore(habit) }
                                } label: {
                                    Label("Restore", systemImage: "arrow.counterclockwise")
                                }
                                .tint(.teal)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Archived Habits")
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.load() }
            .alert("Error", isPresented: Binding(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Button("OK", role: .cancel) { viewModel.error = nil }
            } message: {
                Text(viewModel.error ?? "")
            }
        }
    }
}
