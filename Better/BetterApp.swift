import SwiftUI
import PostHog
import UserNotifications

extension Notification.Name {
    static let openCoachFromNudge = Notification.Name("openCoachFromNudge")
}

@main
struct BetterApp: App {
    @State private var rootViewModel = RootViewModel()
    @State private var showQuickComplete = false
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(rootViewModel)
                .onAppear {
                    RevenueCatManager.shared.configure()
                    PostHogSDK.shared.setup(
                        PostHogConfig(apiKey: Secrets.postHogAPIKey)
                    )
                }
                .onOpenURL { url in
                    if url.host == "quick-complete" {
                        showQuickComplete = true
                    }
                }
                .sheet(isPresented: $showQuickComplete) {
                    QuickCompleteView()
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                }
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        UIApplication.shared.registerForRemoteNotifications()
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task {
            await NotificationManager.shared.uploadDeviceToken(deviceToken)
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let type = userInfo["type"] as? String {
            switch type {
            case "day1_activation":
                PostHogSDK.shared.capture("day1_notification_opened")
            case "coach_nudge":
                PostHogSDK.shared.capture("coach_nudge_opened", properties: [
                    "habit_id": userInfo["habit_id"] as? String ?? ""
                ])
                // Navigate to coach tab — post notification for MainTabView to handle
                NotificationCenter.default.post(name: .openCoachFromNudge, object: nil)
            default:
                break
            }
        }
        completionHandler()
    }
}
