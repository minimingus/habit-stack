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
        for await (_, session) in supabase.auth.authStateChanges {
            self.session = session
            if session != nil {
                await checkOnboardingStatus()
            }
            isLoading = false
        }
    }

    @MainActor
    private func checkOnboardingStatus() async {
        isOnboardingComplete = UserDefaults.standard.bool(forKey: "onboardingComplete")
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
                OnboardingFlow()
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
    @State private var showWhatsNew = false
    @State private var unseenFeatures: [WhatsNewFeature] = []
    private let whatsNewService = WhatsNewService()

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "checkmark.circle.fill") }
            AnalyticsView()
                .tabItem { Label("Analytics", systemImage: "chart.bar.fill") }
            CoachView()
                .tabItem { Label("Coach", systemImage: "bubble.left.fill") }
            FourLawsView()
                .tabItem { Label("Identity", systemImage: "person.crop.circle.badge.checkmark") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Color("Teal"))
        .task {
            whatsNewService.bootstrapIfNeeded()
            NotificationManager.shared.scheduleInactiveUserReminder()
            await checkWeeklyReflection()
            let unseen = whatsNewService.unseenFeatures()
            if !unseen.isEmpty {
                unseenFeatures = unseen
                showWhatsNew = true
            }
        }
        .sheet(isPresented: $showWhatsNew) {
            WhatsNewSheet(features: unseenFeatures) {
                whatsNewService.markAllSeen(unseenFeatures)
                showWhatsNew = false
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showWeeklyReflection) {
            WeeklyReflectionView(habitStats: habitStats, onDismiss: {
                showWeeklyReflection = false
            }, onSnooze: {
                // Set last date to 20h ago so it re-prompts in ~4 hours
                let snoozeDate = Date().addingTimeInterval(-20 * 3600)
                UserDefaults.standard.set(snoozeDate.timeIntervalSince1970, forKey: "lastWeeklyReflectionDate")
                showWeeklyReflection = false
            })
        }
    }

    private func checkWeeklyReflection() async {
        let lastTimestamp = UserDefaults.standard.double(forKey: "lastWeeklyReflectionDate")
        guard lastTimestamp > 0 else {
            // First launch — start the clock, don't show yet
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastWeeklyReflectionDate")
            return
        }
        let last = Date(timeIntervalSince1970: lastTimestamp)
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
