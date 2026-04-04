import SwiftUI

struct AnalyticsView: View {
    @State private var viewModel = AnalyticsViewModel()
    @State private var selectedCell: (date: Date, status: HabitLog.Status?)?
    @State private var showCellSheet = false
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if viewModel.habits.isEmpty {
                        EmptyStateView(
                            icon: "chart.bar",
                            headline: "No habits yet",
                            subtext: "Add habits to see your analytics."
                        )
                        .frame(height: 300)
                    } else {
                        // Weekly consistency score
                        if !viewModel.allHabitsStats.isEmpty {
                            WeeklyConsistencyCard(rate: viewModel.weeklyConsistencyRate)
                                .padding(.horizontal, 16)
                        }

                        // Strongest / weakest (L10 gate)
                        if viewModel.allHabitsStats.count >= 2 {
                            HabitInsightsCard(
                                strongest: viewModel.strongestHabit,
                                weakest: viewModel.weakestHabit,
                                bestTimeOfDay: (viewModel.profile?.level ?? 0) >= 10 ? viewModel.bestTimeOfDay : nil
                            )
                            .overlay(alignment: .topTrailing) {
                                if (viewModel.profile?.level ?? 0) < 10 {
                                    Label("Unlock at Level 10", systemImage: "lock.fill")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color("Stone500"))
                                        .clipShape(Capsule())
                                        .padding(8)
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        // Habit picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Per-Habit Detail")
                                .font(.headline)
                                .foregroundStyle(Color("Stone950"))
                                .padding(.horizontal, 16)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(viewModel.habits) { habit in
                                        Button {
                                            Task { await viewModel.select(habit: habit) }
                                        } label: {
                                            HStack(spacing: 6) {
                                                Text(habit.emoji)
                                                Text(habit.name)
                                                    .font(.subheadline)
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(viewModel.selectedHabit?.id == habit.id ? Color("Teal") : Color("Stone100"))
                                            .foregroundStyle(viewModel.selectedHabit?.id == habit.id ? .white : Color("Stone950"))
                                            .clipShape(Capsule())
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }

                        if !viewModel.isPro {
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(Color("Teal"))
                                Text("Upgrade to Pro for full 5-week history")
                                    .font(.caption)
                                    .foregroundStyle(Color("Stone500"))
                                Spacer()
                                Button("Upgrade") { showPaywall = true }
                                    .font(.caption.bold())
                                    .foregroundStyle(Color("Teal"))
                            }
                            .padding(12)
                            .background(Color("TealLight"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.horizontal, 16)
                        }

                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            // Monthly chain calendar
                            StreakCalendarView(calendarData: viewModel.calendarData)
                                .padding(.horizontal, 16)

                            // Heatmap + legend
                            VStack(alignment: .leading, spacing: 8) {
                                HeatmapView(
                                    cells: viewModel.heatmapData(),
                                    onTap: { cell in
                                        selectedCell = cell
                                        showCellSheet = true
                                    }
                                )
                                HeatmapLegend()
                            }
                            .padding(.horizontal, 16)

                            // Streak bar
                            if let streak = viewModel.streak {
                                StreakBarView(streak: streak)
                                    .padding(.horizontal, 16)
                            }

                            // Day of week chart
                            if !viewModel.dayOfWeekCounts.isEmpty && viewModel.dayOfWeekCounts.contains(where: { $0.count > 0 }) {
                                DayOfWeekChart(data: viewModel.dayOfWeekCounts)
                                    .padding(.horizontal, 16)
                            }

                            // Per-habit streak insights
                            if viewModel.streak != nil {
                                HabitStreakInsightCard(
                                    bestDay: viewModel.bestDayOfWeek,
                                    streakDelta: viewModel.streakDelta,
                                    currentStreak: viewModel.streak?.currentStreak ?? 0,
                                    daysToMilestone: viewModel.daysToNextMilestone,
                                    nextMilestone: viewModel.nextMilestoneTarget
                                )
                                .padding(.horizontal, 16)
                            }

                            // Achievements
                            AchievementsView()
                                .padding(.horizontal, 16)
                                .padding(.bottom, 16)
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color("AppBackground").ignoresSafeArea())
            .navigationTitle("Analytics")
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
            .sheet(isPresented: $showCellSheet) {
                if let cell = selectedCell {
                    CellDetailView(date: cell.date, status: cell.status)
                        .presentationDetents([.medium])
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }
}

// MARK: - Weekly Consistency Card

private struct WeeklyConsistencyCard: View {
    let rate: Double

    private var color: Color {
        if rate >= 0.8 { return Color("Teal") }
        if rate >= 0.5 { return .orange }
        return .red.opacity(0.7)
    }

    private var label: String {
        if rate >= 0.8 { return "Great consistency!" }
        if rate >= 0.5 { return "Room to grow" }
        return "Time to recommit"
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color("Stone100"), lineWidth: 6)
                    .frame(width: 64, height: 64)
                Circle()
                    .trim(from: 0, to: rate)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 64, height: 64)
                    .animation(.spring(duration: 0.6), value: rate)
                Text("\(Int(rate * 100))%")
                    .font(.caption.bold())
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("This Week")
                    .font(.caption)
                    .foregroundStyle(Color("Stone500"))
                Text(label)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color("Stone950"))
                Text("Average across all habits (7 days)")
                    .font(.caption2)
                    .foregroundStyle(Color("Stone500"))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

// MARK: - Habit Insights Card

private struct HabitInsightsCard: View {
    let strongest: (habit: Habit, rate: Double)?
    let weakest: (habit: Habit, rate: Double)?
    var bestTimeOfDay: Habit.TimeOfDay? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(.headline)
                .foregroundStyle(Color("Stone950"))

            HStack(spacing: 12) {
                if let s = strongest {
                    InsightPill(
                        label: "Strongest",
                        emoji: s.habit.emoji,
                        name: s.habit.name,
                        rate: s.rate,
                        color: Color("Teal")
                    )
                }
                if let w = weakest, w.habit.id != strongest?.habit.id {
                    InsightPill(
                        label: "Needs work",
                        emoji: w.habit.emoji,
                        name: w.habit.name,
                        rate: w.rate,
                        color: .orange
                    )
                }
            }

            if let tod = bestTimeOfDay {
                Divider()
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(Color("Teal"))
                    Text("Best time of day")
                        .font(.subheadline)
                        .foregroundStyle(Color("Stone950"))
                    Spacer()
                    Text(tod.rawValue.capitalized)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color("Teal"))
                }
            }
        }
        .padding(16)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

private struct InsightPill: View {
    let label: String
    let emoji: String
    let name: String
    let rate: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2.bold())
                .foregroundStyle(color)
                .textCase(.uppercase)
                .kerning(0.5)
            HStack(spacing: 6) {
                Text(emoji)
                Text(name)
                    .font(.subheadline)
                    .foregroundStyle(Color("Stone950"))
                    .lineLimit(1)
            }
            Text("\(Int(rate * 100))% this week")
                .font(.caption)
                .foregroundStyle(Color("Stone500"))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Heatmap Legend

private struct HeatmapLegend: View {
    var body: some View {
        HStack(spacing: 12) {
            Spacer()
            LegendItem(color: Color("Stone100"), label: "No log")
            LegendItem(color: Color("TealLight"), label: "Skipped")
            LegendItem(color: Color("Teal"), label: "Done")
        }
        .font(.caption2)
        .foregroundStyle(Color("Stone500"))
    }
}

private struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 12, height: 12)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color("Stone500").opacity(0.2), lineWidth: 0.5)
                )
            Text(label)
        }
    }
}

// MARK: - Habit Streak Insight Card

struct HabitStreakInsightCard: View {
    let bestDay: String?
    let streakDelta: Int
    let currentStreak: Int
    let daysToMilestone: Int?
    let nextMilestone: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Streak Insights")
                .font(.headline)
                .foregroundStyle(Color("Stone950"))

            VStack(spacing: 8) {
                // Best day of week
                if let bestDay {
                    InsightRow(
                        icon: "calendar",
                        iconColor: Color("Teal"),
                        text: "You complete this most on **\(bestDay)**"
                    )
                }

                // vs personal best
                if currentStreak > 0 {
                    if streakDelta == 0 {
                        InsightRow(
                            icon: "trophy.fill",
                            iconColor: .orange,
                            text: "**At your personal best** — keep the chain going!"
                        )
                    } else {
                        InsightRow(
                            icon: "arrow.up.right",
                            iconColor: Color("Stone500"),
                            text: "**\(abs(streakDelta)) days** behind your personal best"
                        )
                    }
                }

                // Countdown to next milestone
                if let days = daysToMilestone, let target = nextMilestone {
                    InsightRow(
                        icon: "flag.fill",
                        iconColor: Color("Teal"),
                        text: "**\(days) more days** to reach the \(target)-day milestone"
                    )
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

private struct InsightRow: View {
    let icon: String
    let iconColor: Color
    let text: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(iconColor)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color("Stone950"))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Day of Week Chart

struct DayOfWeekChart: View {
    let data: [(day: String, count: Int)]

    private var maxCount: Int { data.map { $0.count }.max() ?? 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Best Days")
                .font(.headline)
                .foregroundStyle(Color("Stone950"))

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(data, id: \.day) { item in
                    VStack(spacing: 4) {
                        if item.count > 0 {
                            Text("\(item.count)")
                                .font(.caption2.bold())
                                .foregroundStyle(Color("Teal"))
                        }
                        RoundedRectangle(cornerRadius: 4)
                            .fill(item.count > 0 ? Color("Teal") : Color("Stone100"))
                            .frame(
                                height: maxCount > 0
                                    ? max(4, 60 * CGFloat(item.count) / CGFloat(maxCount))
                                    : 4
                            )
                            .animation(.spring(duration: 0.5), value: item.count)
                        Text(item.day)
                            .font(.caption2)
                            .foregroundStyle(Color("Stone500"))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 90)
        }
        .padding(16)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}
