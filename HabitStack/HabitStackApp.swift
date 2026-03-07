import SwiftUI
import PostHog

@main
struct HabitStackApp: App {
    @State private var rootViewModel = RootViewModel()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(rootViewModel)
                .preferredColorScheme(.dark)
                .onAppear {
                    RevenueCatManager.shared.configure()
                    PostHogSDK.shared.setup(
                        PostHogConfig(apiKey: Secrets.postHogAPIKey)
                    )
                }
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
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
}
