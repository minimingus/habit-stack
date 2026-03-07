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
                            subtext: "Start with just one habit. Small beats ambitious.",
                            cta: "Add Habit",
                            onCTA: { showHabitWizard = true }
                        )
                    } else {
                        List {
                            // XP Header (includes identity statement inline)
                            if let profile = viewModel.profile {
                                Section {
                                    XPHeaderView(
                                        profile: profile,
                                        identityStatement: viewModel.topIdentityStatement
                                    )
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                }
                            }

                            // Never Miss Twice banner
                            if viewModel.showNeverMissTwice {
                                Section {
                                    NeverMissTwiceBanner(missedCount: viewModel.neverMissTwiceCount) {
                                        viewModel.showNeverMissTwice = false
                                        viewModel.neverMissTwiceDismissed = true
                                    }
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                }
                            }

                            Section {
                                ProgressRingView(
                                    progress: viewModel.progress,
                                    completed: viewModel.completedHabits,
                                    total: viewModel.totalHabits,
                                    momentumMessage: viewModel.momentumMessage
                                )
                                .frame(maxWidth: .infinity)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }

                            // Daily 1% insight
                            Section {
                                DailyInsightCard()
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
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
                                    .onMove { source, destination in
                                        viewModel.moveHabits(in: timeOfDay, from: source, to: destination)
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
                        if viewModel.xpToastIsIdentity, let statement = viewModel.topIdentityStatement {
                            IdentityToastView(statement: statement)
                                .padding(.bottom, 100)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                        withAnimation { viewModel.showXPToast = false }
                                    }
                                }
                        } else {
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
            .sheet(isPresented: $viewModel.showMilestone) {
                MilestoneCelebrationView(
                    streakDays: viewModel.milestoneStreak,
                    habitName: viewModel.milestoneHabitName,
                    onDismiss: { viewModel.showMilestone = false }
                )
            }
            .sheet(isPresented: $showHabitWizard) {
                HabitWizardView {
                    Task { await viewModel.loadToday() }
                }
            }
            .sheet(item: $editingHabit) { habit in
                HabitWizardView(editingHabit: habit) {
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
