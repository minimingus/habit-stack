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

                        // Strongest / weakest
                        if viewModel.allHabitsStats.count >= 2 {
                            HabitInsightsCard(
                                strongest: viewModel.strongestHabit,
                                weakest: viewModel.weakestHabit
                            )
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
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color("Stone100").ignoresSafeArea())
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
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

// MARK: - Habit Insights Card

private struct HabitInsightsCard: View {
    let strongest: (habit: Habit, rate: Double)?
    let weakest: (habit: Habit, rate: Double)?

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
        }
        .padding(16)
        .background(Color.white)
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
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}
