import Foundation

enum Secrets {
    static let supabaseURL: String = bundle("SupabaseURL")
    static let supabaseAnonKey: String = bundle("SupabaseAnonKey")
    static let revenueCatAPIKey: String = bundle("RevenueCatAPIKey")
    static let postHogAPIKey: String = bundle("PostHogAPIKey")

    private static func bundle(_ key: String) -> String {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let value = dict[key] as? String else {
            fatalError("Missing \(key) in Secrets.plist")
        }
        return value
    }
}
