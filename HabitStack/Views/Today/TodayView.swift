import SwiftUI
import PostHog

struct TodayView: View {
    @State private var viewModel = TodayViewModel()
    @State private var showHabitWizard = false
    @State private var showAddSwipe = false
    @State private var editingHabit: Habit?
    @State private var selectedTab: Int = 0
    @State private var showScorecard = false
    @State private var showPaywall = false
    @State private var showUpgradeNudge = RevenueCatManager.shared.shouldShowUpgradeNudge

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if viewModel.isLoading {
                        SkeletonView()
                    } else if viewModel.totalHabits == 0 {
                        let hasScorecard = !ScorecardEntry.load().isEmpty
                        if hasScorecard {
                            EmptyStateView(
                                icon: "clipboard",
                                headline: "Your inventory is ready",
                                subtext: "You mapped your daily behaviors. Pick one to replace or stack onto — that's how new habits stick.",
                                cta: "Review my behaviors →",
                                onCTA: { showScorecard = true }
                            )
                        } else {
                            EmptyStateView(
                                icon: "checkmark.circle",
                                headline: "No habits yet",
                                subtext: "Start with just one habit. Small beats ambitious.",
                                cta: "Adopt a Habit",
                                onCTA: { showAddSwipe = true }
                            )
                        }
                    } else {
                        List {
                            // Timeline header — date, bold title, progress bar, streak badge
                            Section {
                                TodayHeaderView(
                                    completed: viewModel.completedHabits,
                                    total: viewModel.totalHabits,
                                    bestStreak: viewModel.streaks.values.map { $0.currentStreak }.max() ?? 0
                                )
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }

                            // Trial expiry banner
                            if RevenueCatManager.shared.trialExpiresWithin24h {
                                Section {
                                    TrialExpiryBanner {
                                        PostHogSDK.shared.capture("trial_expiry_banner_tapped")
                                        showPaywall = true
                                    }
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                    .onAppear {
                                        PostHogSDK.shared.capture("trial_expiry_banner_shown")
                                    }
                                }
                            }

                            // Weekly-to-monthly upgrade nudge
                            if showUpgradeNudge {
                                Section {
                                    UpgradeNudgeCard(
                                        onUpgrade: {
                                            Task {
                                                do {
                                                    try await RevenueCatManager.shared.purchaseMonthly()
                                                    PostHogSDK.shared.capture("plan_upgrade_completed", properties: ["from": "weekly", "to": "monthly"])
                                                    showUpgradeNudge = false
                                                } catch {
                                                    viewModel.errorMessage = "Couldn't process upgrade. Please try again."
                                                }
                                            }
                                        },
                                        onDismiss: {
                                            RevenueCatManager.shared.dismissUpgradeNudge()
                                            withAnimation { showUpgradeNudge = false }
                                        }
                                    )
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                }
                            }

                            // Never Miss Twice banner
                            if viewModel.neverMissTwiceState != .dismissed {
                                Section {
                                    NeverMissTwiceBanner(
                                        state: viewModel.neverMissTwiceState,
                                        missedCount: viewModel.neverMissTwiceCount,
                                        recoveryHabitCount: viewModel.recoveryHabitCount,
                                        profile: viewModel.profile,
                                        onDismiss: {
                                            viewModel.dismissNeverMissTwice()
                                        },
                                        onUseShield: {
                                            Task { await viewModel.spendStreakShield() }
                                        }
                                    )
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                }
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
                                                do {
                                                    try await HabitService.shared.archiveHabit(habitWithStatus.habit.id)
                                                } catch {
                                                    viewModel.errorMessage = "Couldn't archive habit. Please try again."
                                                    PostHogSDK.shared.capture("error_occurred", properties: ["source": "archive_habit", "message": error.localizedDescription])
                                                }
                                                await viewModel.loadToday()
                                            }},
                                            onPause: { until in
                                                Task { await viewModel.pauseHabit(habitWithStatus.habit, until: until) }
                                            }
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
                            // Paused habits section
                            if !viewModel.pausedHabits.isEmpty {
                                Section {
                                    ForEach(viewModel.pausedHabits) { habit in
                                        PausedHabitRow(habit: habit) {
                                            Task { await viewModel.resumeHabit(habit) }
                                        }
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                    }
                                } header: {
                                    HStack {
                                        Image(systemName: "pause.circle.fill")
                                            .foregroundStyle(Color("Stone500"))
                                        Text("Paused")
                                            .font(.subheadline.bold())
                                            .foregroundStyle(Color("Stone500"))
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .refreshable { await viewModel.loadToday() }
                    }
                }

                // Completion toast overlay
                if viewModel.showXPToast {
                    VStack {
                        Spacer()
                        CompletionToastView(
                            xpAmount: viewModel.xpToastAmount,
                            identityStatement: viewModel.topIdentityStatement,
                            voteCount: viewModel.identityVoteCount
                        )
                        .padding(.bottom, 100)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                withAnimation { viewModel.showXPToast = false }
                            }
                        }
                    }
                }

                // FAB
                Button {
                    showAddSwipe = true
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
            .navigationTitle("")
            .navigationBarHidden(true)
            .errorToast($viewModel.errorMessage)
            .task {
                await viewModel.loadToday()
                showUpgradeNudge = RevenueCatManager.shared.shouldShowUpgradeNudge
            }
            .sheet(isPresented: $viewModel.showMilestone) {
                MilestoneCelebrationView(
                    streakDays: viewModel.milestoneStreak,
                    habitName: viewModel.milestoneHabitName,
                    onDismiss: { viewModel.showMilestone = false }
                )
            }
            .sheet(isPresented: $showAddSwipe) {
                AddHabitSwipeView {
                    Task { await viewModel.loadToday() }
                }
            }
            .sheet(isPresented: $showHabitWizard) {
                HabitWizardView {
                    Task { await viewModel.loadToday() }
                }
            }
            .sheet(isPresented: $showScorecard, onDismiss: {
                Task { await viewModel.loadToday() }
            }) {
                HabitsScorecardView()
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .onChange(of: viewModel.completedHabits) { _, newCount in
                checkFirstUsePaywall(completedCount: newCount)
            }
            .sheet(item: $editingHabit) { habit in
                HabitWizardView(
                    editingHabit: habit,
                    editingStreak: viewModel.streaks[habit.id]?.currentStreak ?? 0
                ) {
                    Task { await viewModel.loadToday() }
                }
            }
        }
    }

    private func checkFirstUsePaywall(completedCount: Int) {
        guard completedCount >= 3,
              !UserDefaults.standard.bool(forKey: "hasSeenFirstUsePaywall"),
              !RevenueCatManager.shared.isProUser else { return }
        UserDefaults.standard.set(true, forKey: "hasSeenFirstUsePaywall")
        PostHogSDK.shared.capture("first_use_paywall_shown", properties: [
            "completed_habits": completedCount
        ])
        // Small delay so the completion animation plays first
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showPaywall = true
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
