import SwiftUI
import PostHog

struct QuickCompleteView: View {
    @State private var viewModel = TodayViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if incompleteHabits.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Color("Teal"))
                        Text("All done for today!")
                            .font(.title3.bold())
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(incompleteHabits) { habitWithStatus in
                            Button {
                                Task { await viewModel.toggleHabit(habitWithStatus) }
                            } label: {
                                HStack(spacing: 14) {
                                    Text(habitWithStatus.habit.emoji)
                                        .font(.title2)
                                    Text(habitWithStatus.habit.name)
                                        .font(.body)
                                    Spacer()
                                    if habitWithStatus.isCompleted {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color("Teal"))
                                            .font(.title3)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundStyle(.secondary)
                                            .font(.title3)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Quick Complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task {
            PostHogSDK.shared.capture("quick_complete_opened", properties: ["source": "widget"])
            await viewModel.loadToday()
        }
    }

    private var incompleteHabits: [HabitWithStatus] {
        viewModel.orderedGroups.flatMap { $0.1 }
    }
}
