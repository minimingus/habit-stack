import SwiftUI

struct SettingsView: View {
    @Environment(RootViewModel.self) var rootViewModel
    @State private var showSignOutAlert = false
    @State private var showResetAlert = false
    @State private var showPaywall = false
    @State private var showAdminSpend = false
    @State private var versionTapCount = 0
    @State private var profile: Profile?
    @State private var userEmail: String?
    @AppStorage("compactCardMode") private var compactCardMode = false

    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    var body: some View {
        NavigationStack {
            List {
                // Account
                Section("Account") {
                    if let email = userEmail {
                        LabeledContent("Email") {
                            Text(email)
                                .foregroundStyle(Color("Stone500"))
                        }
                    }
                    if let profile {
                        if let name = profile.name, !name.isEmpty {
                            LabeledContent("Name") {
                                Text(name)
                                    .foregroundStyle(Color("Stone500"))
                            }
                        }
                        LabeledContent("Plan") {
                            Text(profile.plan == .pro ? "Pro" : "Free")
                                .fontWeight(.semibold)
                                .foregroundStyle(profile.plan == .pro ? Color("Teal") : Color("Stone500"))
                        }
                    }
                }

                // Subscription
                if FeatureFlags.revenueCatEnabled {
                    Section("Subscription") {
                        if RevenueCatManager.shared.isProUser {
                            Button("Manage Subscription") {
                                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        } else {
                            Button("Upgrade to Pro") { showPaywall = true }
                                .foregroundStyle(Color("Teal"))
                        }
                    }
                }

                // Notifications
                Section("Notifications") {
                    Button("Notification Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }

                // Appearance
                Section("Appearance") {
                    Toggle(isOn: $compactCardMode) {
                        Label("Compact Cards", systemImage: "rectangle.compress.vertical")
                    }
                    .tint(Color("Teal"))
                }

                // Data
                Section("Data") {
                    NavigationLink("Archived Habits") {
                        ArchivedHabitsView()
                    }
                }

                // Developer
                Section("Developer") {
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        Label("Reset App Data", systemImage: "trash")
                    }
                }

                // About
                Section("About") {
                    LabeledContent("Version") {
                        Text(appVersion)
                            .foregroundStyle(Color("Stone500"))
                    }
                    .onTapGesture {
                        versionTapCount += 1
                        if versionTapCount >= 7 { showAdminSpend = true }
                    }
                    Link("Privacy Policy", destination: URL(string: "https://habitstack.app/privacy")!)
                    Link("Support", destination: URL(string: "https://habitstack.app/support")!)
                }
            }
            .navigationTitle("Settings")
            .safeAreaInset(edge: .bottom) {
                Button(role: .destructive) {
                    showSignOutAlert = true
                } label: {
                    Text("Sign Out")
                        .fontWeight(.semibold)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemBackground))
                        .overlay(alignment: .top) {
                            Divider()
                        }
                }
            }
            .task { await loadProfile() }
            .alert("Sign Out?", isPresented: $showSignOutAlert) {
                Button("Sign Out", role: .destructive) {
                    Task { try? await rootViewModel.signOut() }
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Reset App Data?", isPresented: $showResetAlert) {
                Button("Reset", role: .destructive) {
                    Task { await resetAppData() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Clears all local data and signs you out. You will need to sign in again.")
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showAdminSpend) { AdminSpendView() }
        }
    }

    private func resetAppData() async {
        if let bundleId = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleId)
        }
        try? await supabase.auth.signOut()
    }

    private func loadProfile() async {
        guard let user = try? await supabase.auth.session.user else { return }
        userEmail = user.email
        profile = try? await supabase
            .from("profiles")
            .select()
            .eq("id", value: user.id.uuidString)
            .single()
            .execute()
            .value
    }
}
