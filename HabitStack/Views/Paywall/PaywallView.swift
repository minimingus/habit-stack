import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: Plan = .annual
    @State private var isLoading = false
    @State private var errorMessage: String?

    enum Plan { case monthly, annual }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Color("Teal"))
                        Text("Upgrade to Pro")
                            .font(.title.bold())
                        Text("Unlock all features and build habits without limits.")
                            .font(.subheadline)
                            .foregroundStyle(Color("Stone500"))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 32)
                    .padding(.horizontal, 24)

                    // Features list
                    VStack(alignment: .leading, spacing: 12) {
                        ProFeatureRow(icon: "infinity", text: "Unlimited habits (free: 5 max)")
                        ProFeatureRow(icon: "chart.bar.fill", text: "Full 5-week analytics history")
                        ProFeatureRow(icon: "bubble.left.fill", text: "50 AI coach messages per day")
                    }
                    .padding(.horizontal, 24)

                    // Plan selector
                    VStack(spacing: 10) {
                        PlanButton(
                            title: "Annual",
                            price: "$59.99/year",
                            badge: "Save 37%",
                            isSelected: selectedPlan == .annual,
                            onSelect: { selectedPlan = .annual }
                        )
                        PlanButton(
                            title: "Monthly",
                            price: "$7.99/month",
                            badge: nil,
                            isSelected: selectedPlan == .monthly,
                            onSelect: { selectedPlan = .monthly }
                        )
                    }
                    .padding(.horizontal, 24)

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 24)
                    }

                    VStack(spacing: 12) {
                        Button {
                            Task { await purchase() }
                        } label: {
                            Group {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Subscribe")
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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Maybe Later") { dismiss() }
                        .foregroundStyle(Color("Stone500"))
                }
            }
        }
    }

    private func purchase() async {
        isLoading = true
        errorMessage = nil
        do {
            if selectedPlan == .annual {
                try await RevenueCatManager.shared.purchaseAnnual()
            } else {
                try await RevenueCatManager.shared.purchaseMonthly()
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
