import SwiftUI
import PostHog

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: Plan = .weekly
    @State private var isLoading = false
    @State private var errorMessage: String?

    enum Plan { case weekly, monthly, annual }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Color("Teal"))

                        if RevenueCatManager.shared.isOnTrial, let days = RevenueCatManager.shared.trialDaysRemaining {
                            Text("Pro Trial Active")
                                .font(.title.bold())
                            Text("\(days) day\(days == 1 ? "" : "s") remaining")
                                .font(.subheadline)
                                .foregroundStyle(Color("Teal"))
                        } else {
                            Text("Become who you want to be")
                                .font(.title.bold())
                            Text("Unlock your full potential with unlimited habits and personal AI coaching.")
                                .font(.subheadline)
                                .foregroundStyle(Color("Stone500"))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 32)
                    .padding(.horizontal, 24)

                    // Features list
                    VStack(alignment: .leading, spacing: 12) {
                        ProFeatureRow(icon: "bubble.left.fill", text: "Personal AI coach — 50 messages/day")
                        ProFeatureRow(icon: "infinity", text: "Unlimited habits to match your goals")
                        ProFeatureRow(icon: "chart.bar.fill", text: "5 weeks of progress insights")
                    }
                    .padding(.horizontal, 24)

                    if !RevenueCatManager.shared.isOnTrial {
                        // Trial messaging
                        Text("Try Pro free. Cancel anytime.")
                            .font(.subheadline)
                            .foregroundStyle(Color("Stone500"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        // Plan selector
                        VStack(spacing: 10) {
                            PlanButton(
                                title: "Weekly",
                                price: "3-day free trial, then $2.99/week",
                                badge: "Most Popular",
                                isSelected: selectedPlan == .weekly,
                                onSelect: { selectedPlan = .weekly }
                            )
                            PlanButton(
                                title: "Monthly",
                                price: "7-day free trial, then $7.99/month",
                                badge: "Save 33%",
                                isSelected: selectedPlan == .monthly,
                                onSelect: { selectedPlan = .monthly }
                            )
                            PlanButton(
                                title: "Annual",
                                price: "7-day free trial, then $59.99/year",
                                badge: "Best Value",
                                isSelected: selectedPlan == .annual,
                                onSelect: { selectedPlan = .annual }
                            )
                        }
                        .padding(.horizontal, 24)
                    }

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 24)
                    }

                    VStack(spacing: 12) {
                        if RevenueCatManager.shared.isOnTrial {
                            Button {
                                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                Text("Manage Subscription")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color("Teal"))
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        } else {
                            Button {
                                Task { await purchase() }
                            } label: {
                                Group {
                                    if isLoading {
                                        ProgressView().tint(.white)
                                    } else {
                                        Text(selectedPlan == .weekly ? "Try for $2.99/week" : "Start Free Trial")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("Teal"))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .disabled(isLoading)
                        }

                        Button {
                            Task { await restore() }
                        } label: {
                            Text("Restore Purchases")
                                .font(.subheadline)
                                .foregroundStyle(Color("Stone500"))
                        }
                    }
                    .padding(.horizontal, 24)

                    Text("Cancel anytime. Billed through Apple.")
                        .font(.caption)
                        .foregroundStyle(Color("Stone500"))
                        .padding(.bottom, 24)
                }
            }
            .onAppear {
                PostHogSDK.shared.capture("paywall_shown")
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Maybe Later") {
                        PostHogSDK.shared.capture("paywall_dismissed")
                        dismiss()
                    }
                        .foregroundStyle(Color("Stone500"))
                }
            }
        }
    }

    private var planName: String {
        switch selectedPlan {
        case .weekly: return "weekly"
        case .monthly: return "monthly"
        case .annual: return "annual"
        }
    }

    private func purchase() async {
        isLoading = true
        errorMessage = nil
        PostHogSDK.shared.capture("purchase_started", properties: ["plan": planName])
        do {
            switch selectedPlan {
            case .weekly:
                try await RevenueCatManager.shared.purchaseWeekly()
            case .monthly:
                try await RevenueCatManager.shared.purchaseMonthly()
            case .annual:
                try await RevenueCatManager.shared.purchaseAnnual()
            }
            if RevenueCatManager.shared.isOnTrial {
                PostHogSDK.shared.capture("trial_started", properties: ["plan": planName])
            } else {
                PostHogSDK.shared.capture("purchase_completed", properties: ["plan": planName])
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func restore() async {
        isLoading = true
        do {
            try await RevenueCatManager.shared.restorePurchases()
            PostHogSDK.shared.capture("purchase_restored")
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

private struct ProFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color("Teal"))
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
}

private struct PlanButton: View {
    let title: String
    let price: String
    let badge: String?
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.bold())
                    Text(price)
                        .font(.caption)
                        .foregroundStyle(Color("Stone500"))
                }
                Spacer()
                if let badge {
                    Text(badge)
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color("TealLight"))
                        .foregroundStyle(Color("Teal"))
                        .clipShape(Capsule())
                }
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color("Teal") : Color("Stone500"))
            }
            .padding(14)
            .background(isSelected ? Color("TealLight") : Color("Stone100"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color("Teal"), lineWidth: 1.5)
                }
            }
        }
        .foregroundStyle(Color("Stone950"))
    }
}
