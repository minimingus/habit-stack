import Foundation
import RevenueCat
import Observation
import PostHog

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

    func purchaseWeekly() async throws {
        guard FeatureFlags.revenueCatEnabled else { return }
        let offerings = try await Purchases.shared.offerings()
        guard let weekly = offerings.current?.weekly else { return }
        let result = try await Purchases.shared.purchase(package: weekly)
        updateEntitlementState(from: result.customerInfo)
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

    var isWeeklySubscriber: Bool {
        guard FeatureFlags.revenueCatEnabled else { return false }
        return _isWeeklySubscriber
    }
    private var _isWeeklySubscriber = false

    var originalPurchaseDate: Date? {
        guard FeatureFlags.revenueCatEnabled else { return nil }
        return _originalPurchaseDate
    }
    private var _originalPurchaseDate: Date?

    var shouldShowUpgradeNudge: Bool {
        guard isProUser, isWeeklySubscriber, !isOnTrial else { return false }
        guard let purchaseDate = originalPurchaseDate else { return false }
        let daysSincePurchase = Calendar.current.dateComponents([.day], from: purchaseDate, to: Date()).day ?? 0
        guard daysSincePurchase >= 28 else { return false }
        let dismissCount = UserDefaults.standard.integer(forKey: "upgradeNudgeDismissCount")
        return dismissCount < 3
    }

    func dismissUpgradeNudge() {
        let key = "upgradeNudgeDismissCount"
        let count = UserDefaults.standard.integer(forKey: key)
        UserDefaults.standard.set(count + 1, forKey: key)
    }

    var trialExpiresWithin24h: Bool {
        guard let expiration = trialExpirationDate, isOnTrial else { return false }
        let hoursRemaining = expiration.timeIntervalSince(Date()) / 3600
        return hoursRemaining > 0 && hoursRemaining <= 24
    }

    var trialHoursRemaining: Int? {
        guard let expiration = trialExpirationDate, isOnTrial else { return nil }
        let hours = Int(expiration.timeIntervalSince(Date()) / 3600)
        return max(0, hours)
    }

    private func updateEntitlementState(from info: CustomerInfo) {
        let proEntitlement = info.entitlements["pro"]
        let wasTrial = _isOnTrial
        _isProUser = proEntitlement?.isActive == true
        _isOnTrial = proEntitlement?.periodType == .trial
        _trialExpirationDate = proEntitlement?.expirationDate

        // Track weekly subscription status for upgrade nudge
        _isWeeklySubscriber = info.activeSubscriptions.contains { $0.lowercased().contains("weekly") || $0.lowercased().contains("week") }
        _originalPurchaseDate = info.originalPurchaseDate

        // Schedule trial expiry notifications when trial is first detected
        if _isOnTrial, let expDate = _trialExpirationDate, !wasTrial {
            NotificationManager.shared.scheduleTrialExpiryNotifications(expirationDate: expDate)
            PostHogSDK.shared.capture("trial_expiry_notification_sent", properties: [
                "hours_remaining": Int(expDate.timeIntervalSince(Date()) / 3600)
            ])
        }

        // Cancel trial notifications if user converted
        if !_isOnTrial && wasTrial && _isProUser {
            NotificationManager.shared.cancelTrialExpiryNotifications()
        }
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
