import SwiftUI
import Supabase
import Observation

@Observable
final class RootViewModel {
    var session: Session? = nil
    var isOnboardingComplete: Bool = false
    var isLoading: Bool = true

    init() {
        Task { await observeAuth() }
    }

    @MainActor
    private func observeAuth() async {
        isLoading = true
        for await (event, session) in supabase.auth.authStateChanges {
            self.session = session
            if session != nil {
                await checkOnboardingStatus()
            }
            isLoading = false
        }
    }

    @MainActor
    private func checkOnboardingStatus() async {
        guard let userId = session?.user.id else { return }
        let profiles: [Profile] = (try? await supabase
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value) ?? []
        isOnboardingComplete = profiles.first?.scorecardResult != nil
    }

    func signOut() async throws {
        try await supabase.auth.signOut()
    }
}

struct RootView: View {
    @Environment(RootViewModel.self) var viewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.session == nil {
                AuthView()
            } else if !viewModel.isOnboardingComplete {
                OnboardingContainerView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut, value: viewModel.session?.user.id)
    }
}

struct MainTabView: View {
    @State private var showWeeklyReflection = false
    @State private var habitStats: [(name: String, emoji: String, completionRate: Double)] = []

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "checkmark.circle.fill") }
            AnalyticsView()
                .tabItem { Label("Analytics", systemImage: "chart.bar.fill") }
            CoachView()
                .tabItem { Label("Coach", systemImage: "bubble.left.fill") }
            FourLawsView()
                .tabItem { Label("Four Laws", systemImage: "4.circle.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Color("Teal"))
        .task { await checkWeeklyReflection() }
        .sheet(isPresented: $showWeeklyReflection) {
            WeeklyReflectionView(habitStats: habitStats) {
                showWeeklyReflection = false
            }
        }
    }

    private func checkWeeklyReflection() async {
        let lastTimestamp = UserDefaults.standard.double(forKey: "lastWeeklyReflectionDate")
        let last = lastTimestamp > 0 ? Date(timeIntervalSince1970: lastTimestamp) : .distantPast
        let daysSince = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
        guard daysSince >= 7 else { return }

        // Load habit completion stats for the past 7 days
        guard let userId = try? await supabase.auth.session.user.id else { return }
        let habits: [Habit] = (try? await supabase
            .from("habits")
            .select()
            .eq("user_id", value: userId.uuidString)
            .is("archived_at", value: nil)
            .execute()
            .value) ?? []

        var stats: [(name: String, emoji: String, completionRate: Double)] = []
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        for habit in habits {
            let logs: [HabitLog] = (try? await supabase
                .from("habit_logs")
                .select()
                .eq("habit_id", value: habit.id.uuidString)
                .gte("logged_at", value: ISO8601DateFormatter().string(from: weekAgo))
                .execute()
                .value) ?? []
            let doneCount = logs.filter { $0.status == .done }.count
            stats.append((name: habit.name, emoji: habit.emoji, completionRate: Double(doneCount) / 7.0))
        }

        await MainActor.run {
            habitStats = stats
            showWeeklyReflection = true
        }
    }
}
