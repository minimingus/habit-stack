import SwiftUI

struct TodayView: View {
    @State private var viewModel = TodayViewModel()
    @State private var showHabitWizard = false
    @State private var editingHabit: Habit?
    @State private var selectedTab: Int = 0

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if viewModel.isLoading {
                        SkeletonView()
                    } else if viewModel.totalHabits == 0 {
                        EmptyStateView(
                            icon: "checkmark.circle",
                            headline: "No habits yet",
                            subtext: "Tap + to add your first habit.",
                            cta: "Add Habit",
                            onCTA: { showHabitWizard = true }
                        )
                    } else {
                        List {
                            // XP Header
                            if let profile = viewModel.profile {
                                Section {
                                    XPHeaderView(profile: profile)
                                        .listRowBackground(Color.clear)
                                        .listRowSeparator(.hidden)
                                }
                            }

                            // Never Miss Twice banner
                            if viewModel.showNeverMissTwice {
                                Section {
                                    NeverMissTwiceBanner {
                                        viewModel.showNeverMissTwice = false
                                        viewModel.neverMissTwiceDismissed = true
                                    }
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                }
                            }

                            // Identity statement
                            if let identity = viewModel.topIdentityStatement {
                                Section {
                                    IdentityStatementBanner(statement: identity)
                                        .listRowBackground(Color.clear)
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                                }
                            }

                            Section {
                                ProgressRingView(
                                    progress: viewModel.progress,
                                    completed: viewModel.completedHabits,
                                    total: viewModel.totalHabits
                                )
                                .frame(maxWidth: .infinity)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }

                            ForEach(viewModel.orderedGroups, id: \.0) { (timeOfDay, habits) in
                                Section {
                                    ForEach(habits) { habitWithStatus in
                                        HabitCardView(
                                            habitWithStatus: habitWithStatus,
                                            streak: viewModel.streaks[habitWithStatus.habit.id],
                                            anchorName: anchorName(for: habitWithStatus.habit),
                                            onToggle: { Task { await viewModel.toggleHabit(habitWithStatus) } },
                                            onEdit: { editingHabit = habitWithStatus.habit },
                                            onArchive: { Task {
                                                try? await HabitService.shared.archiveHabit(habitWithStatus.habit.id)
                                                await viewModel.loadToday()
                                            }}
                                        )
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                    }
                                } header: {
                                    HabitGroupView(timeOfDay: timeOfDay, count: habits.count)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .refreshable { await viewModel.loadToday() }
                    }
                }

                // XP toast overlay
                if viewModel.showXPToast {
                    VStack {
                        Spacer()
                        XPToastView(amount: viewModel.xpToastAmount)
                            .padding(.bottom, 100)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation { viewModel.showXPToast = false }
                                }
                            }
                    }
                }

                // FAB
                Button {
                    showHabitWizard = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Color("Teal"))
                        .clipShape(Circle())
                        .shadow(radius: 4, y: 2)
                }
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
            .navigationTitle("Today")
            .task { await viewModel.loadToday() }
            .sheet(isPresented: $showHabitWizard) {
                HabitWizardView(prefillTemplate: nil) {
                    Task { await viewModel.loadToday() }
                }
            }
            .sheet(item: $editingHabit) { habit in
                HabitWizardView(prefillTemplate: nil, editingHabit: habit) {
                    Task { await viewModel.loadToday() }
                }
            }
        }
    }

    private func anchorName(for habit: Habit) -> String? {
        guard let anchorId = habit.anchorHabitId else { return nil }
        return viewModel.habitGroups.values
            .flatMap { $0 }
            .first { $0.habit.id == anchorId }?
            .habit.name
    }
}
