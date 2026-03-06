import SwiftUI

struct AnalyticsView: View {
    @State private var viewModel = AnalyticsViewModel()
    @State private var selectedCell: (date: Date, status: HabitLog.Status?)?
    @State private var showCellSheet = false
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if viewModel.habits.isEmpty {
                        EmptyStateView(
                            icon: "chart.bar",
                            headline: "No habits yet",
                            subtext: "Add habits to see your analytics."
                        )
                        .frame(height: 300)
                    } else {
                        // Habit picker
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
                            HeatmapView(
                                cells: viewModel.heatmapData(),
                                onTap: { cell in
                                    selectedCell = cell
                                    showCellSheet = true
                                }
                            )
                            .padding(.horizontal, 16)

                            if let streak = viewModel.streak {
                                StreakBarView(streak: streak)
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            .navigationTitle("Analytics")
            .task { await viewModel.load() }
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
