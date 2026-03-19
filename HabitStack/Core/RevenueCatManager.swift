import Foundation
import RevenueCat
import Observation

@Observable
final class RevenueCatManager {
    static let shared = RevenueCatManager()
    private init() {}

    var isProUser: Bool {
        guard FeatureFlags.revenueCatEnabled else { return true }
        return _isProUser
    }
    private var _isProUser: Bool = false

    var isOnTrial: Bool {
        guard FeatureFlags.revenueCatEnabled else { return false }
        return _isOnTrial
    }
    private var _isOnTrial: Bool = false

    var trialExpirationDate: Date? {
        guard FeatureFlags.revenueCatEnabled else { return nil }
        return _trialExpirationDate
    }
    private var _trialExpirationDate: Date?

    var trialDaysRemaining: Int? {
        guard let expiration = trialExpirationDate else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expiration).day ?? 0
        return max(0, days)
    }

    func configure() {
        guard FeatureFlags.revenueCatEnabled else { return }
        Purchases.configure(withAPIKey: Secrets.revenueCatAPIKey)
        Purchases.shared.delegate = RevenueCatDelegate.shared
        Task { await refreshStatus() }
    }

    func refreshStatus() async {
        guard FeatureFlags.revenueCatEnabled else { return }
        guard let info = try? await Purchases.shared.customerInfo() else { return }
        updateEntitlementState(from: info)
        await syncPlanWithSupabase()
    }

    func purchaseMonthly() async throws {
        guard FeatureFlags.revenueCatEnabled else { return }
        let offerings = try await Purchases.shared.offerings()
        guard let monthly = offerings.current?.monthly else { return }
        let result = try await Purchases.shared.purchase(package: monthly)
        updateEntitlementState(from: result.customerInfo)
        await syncPlanWithSupabase()
    }

    func purchaseAnnual() async throws {
        guard FeatureFlags.revenueCatEnabled else { return }
        let offerings = try await Purchases.shared.offerings()
        guard let annual = offerings.current?.annual else { return }
        let result = try await Purchases.shared.purchase(package: annual)
        updateEntitlementState(from: result.customerInfo)
        await syncPlanWithSupabase()
    }

    func restorePurchases() async throws {
        guard FeatureFlags.revenueCatEnabled else { return }
        let info = try await Purchases.shared.restorePurchases()
        updateEntitlementState(from: info)
        await syncPlanWithSupabase()
    }

    private func updateEntitlementState(from info: CustomerInfo) {
        let proEntitlement = info.entitlements["pro"]
        _isProUser = proEntitlement?.isActive == true
        _isOnTrial = proEntitlement?.periodType == .trial
        _trialExpirationDate = proEntitlement?.expirationDate
    }

    private func syncPlanWithSupabase() async {
        guard let userId = try? await supabase.auth.session.user.id else { return }
        let plan = isProUser ? "pro" : "free"
        _ = try? await supabase
            .from("profiles")
            .update(["plan": plan])
            .eq("id", value: userId.uuidString)
            .execute()
    }
}

private final class RevenueCatDelegate: NSObject, PurchasesDelegate {
    static let shared = RevenueCatDelegate()
    private override init() {}

    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task {
            await RevenueCatManager.shared.refreshStatus()
        }
    }
}
