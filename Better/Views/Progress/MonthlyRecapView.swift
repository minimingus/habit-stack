import SwiftUI
import PostHog

struct MonthlyRecapView: View {
    let onDismiss: () -> Void

    @State private var viewModel = MonthlyRecapViewModel()
    @State private var showShareSheet = false
    @State private var shareUIImage: UIImage?
    @State private var showPaywall = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let stats = viewModel.stats {
                recapContent(stats)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("AppBackground").ignoresSafeArea())
        .presentationDetents([.large])
        .sheet(isPresented: $showShareSheet) {
            if let img = shareUIImage {
                let shareText = "\(stats?.monthName ?? "Monthly") recap: \(ratePercent)% completion! Track your habits with Better You: \(Self.appStoreURL)"
                ShareSheet(items: [img, shareText])
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .task {
            await viewModel.load()
        }
    }

    private static let appStoreURL = "https://apps.apple.com/app/better-you"

    private var stats: MonthlyRecapStats? { viewModel.stats }
    private var ratePercent: Int { Int((stats?.overallCompletionRate ?? 0) * 100) }

    @ViewBuilder
    private func recapContent(_ stats: MonthlyRecapStats) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("📊")
                        .font(.system(size: 64))
                        .padding(.top, 32)

                    Text("\(stats.monthName) Recap")
                        .font(.title.bold())
                        .foregroundStyle(Color("Stone950"))

                    HStack(spacing: 4) {
                        trendIcon(stats.trend)
                        Text(trendLabel(stats.trend))
                            .font(.subheadline)
                            .foregroundStyle(trendColor(stats.trend))
                    }
                }
                .padding(.bottom, 24)

                // Overall completion
                completionCard(stats)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                // Stats row
                statsRow(stats)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                // Top habit
                if let top = stats.topHabit {
                    topHabitCard(top)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                }

                // Identity votes
                if stats.identityVotesCast > 0 {
                    identityCard(stats)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                }

                // Paywall banner for free users
                if !RevenueCatManager.shared.isProUser {
                    Button {
                        PostHogSDK.shared.capture("paywall_shown", properties: ["trigger": "monthly_recap"])
                        showPaywall = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .foregroundStyle(Color("Teal"))
                            Text("Unlock unlimited habits with Pro")
                                .font(.subheadline.bold())
                                .foregroundStyle(Color("Stone950"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color("TealLight"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }

                // Action buttons
                VStack(spacing: 12) {
                    Button(action: onDismiss) {
                        Text("Keep Building")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color("Teal"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button {
                        renderShareCard(stats)
                    } label: {
                        Label("Share Recap", systemImage: "square.and.arrow.up")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color("Teal"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color("TealLight"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }

    // MARK: - Cards

    private func completionCard(_ stats: MonthlyRecapStats) -> some View {
        VStack(spacing: 12) {
            Text("\(Int(stats.overallCompletionRate * 100))%")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(Color("Teal"))

            Text("Overall Completion")
                .font(.subheadline)
                .foregroundStyle(Color("Stone500"))

            ProgressView(value: stats.overallCompletionRate)
                .tint(Color("Teal"))
                .padding(.horizontal, 20)

            Text("\(stats.totalCompleted) of \(stats.totalPossible) possible")
                .font(.caption)
                .foregroundStyle(Color("Stone500"))
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    private func statsRow(_ stats: MonthlyRecapStats) -> some View {
        HStack(spacing: 12) {
            statBox(
                icon: "flame.fill",
                value: "\(stats.longestStreakAchieved)",
                label: "Best Streak"
            )
            statBox(
                icon: "list.bullet",
                value: "\(stats.habitCount)",
                label: "Habits"
            )
            statBox(
                icon: "hand.thumbsup.fill",
                value: "\(stats.identityVotesCast)",
                label: "Votes"
            )
        }
    }

    private func statBox(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color("Teal"))
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(Color("Stone950"))
            Text(label)
                .font(.caption)
                .foregroundStyle(Color("Stone500"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    private func topHabitCard(_ top: (name: String, emoji: String, rate: Double)) -> some View {
        HStack(spacing: 12) {
            Text(top.emoji)
                .font(.system(size: 36))

            VStack(alignment: .leading, spacing: 4) {
                Text("Strongest Habit")
                    .font(.caption)
                    .foregroundStyle(Color("Stone500"))
                Text(top.name)
                    .font(.headline)
                    .foregroundStyle(Color("Stone950"))
                Text("\(Int(top.rate * 100))% completion")
                    .font(.subheadline)
                    .foregroundStyle(Color("Teal"))
            }

            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    private func identityCard(_ stats: MonthlyRecapStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .foregroundStyle(Color("Teal"))
                Text("Identity Votes")
                    .font(.headline)
                    .foregroundStyle(Color("Stone950"))
            }

            ForEach(stats.votesByTrait.prefix(3), id: \.trait) { item in
                HStack {
                    Text(item.trait)
                        .font(.subheadline)
                        .foregroundStyle(Color("Stone950"))
                        .lineLimit(1)
                    Spacer()
                    Text("\(item.count) votes")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color("Teal"))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    // MARK: - Trend helpers

    private func trendIcon(_ trend: MonthlyRecapStats.Trend) -> some View {
        Image(systemName: {
            switch trend {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .stable: return "arrow.right"
            }
        }())
        .font(.subheadline.bold())
        .foregroundStyle(trendColor(trend))
    }

    private func trendLabel(_ trend: MonthlyRecapStats.Trend) -> String {
        switch trend {
        case .up: return "Improving vs last month"
        case .down: return "Down vs last month"
        case .stable: return "Steady vs last month"
        }
    }

    private func trendColor(_ trend: MonthlyRecapStats.Trend) -> Color {
        switch trend {
        case .up: return .green
        case .down: return .orange
        case .stable: return Color("Stone500")
        }
    }

    // MARK: - Share

    @MainActor
    private func renderShareCard(_ stats: MonthlyRecapStats) {
        let card = MonthlyRecapShareCard(
            monthName: stats.monthName,
            completionRate: stats.overallCompletionRate,
            habitsCompleted: stats.totalCompleted,
            identityVotes: stats.identityVotesCast,
            topHabitName: stats.topHabit?.name,
            topHabitEmoji: stats.topHabit?.emoji
        )
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0
        shareUIImage = renderer.uiImage

        PostHogSDK.shared.capture("monthly_recap_shared", properties: [
            "month": stats.monthName,
            "completion_rate": stats.overallCompletionRate
        ])

        showShareSheet = true
    }
}
