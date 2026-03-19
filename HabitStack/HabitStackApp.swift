import SwiftUI
import PostHog

@main
struct HabitStackApp: App {
    @State private var rootViewModel = RootViewModel()
    @State private var showQuickComplete = false
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
