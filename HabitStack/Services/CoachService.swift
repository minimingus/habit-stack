import Foundation

enum CoachError: Error {
    case rateLimitReached
    case networkError(Error)
}

struct HabitContext {
    struct HabitInfo {
        let name: String
        let emoji: String
        let currentStreak: Int
        let isCompletedToday: Bool
    }

    let habits: [HabitInfo]
    let identityTraits: [String]

    func toDictionary() -> [String: Any] {
        [
            "habits": habits.map { habit in
                [
                    "name": habit.name,
                    "emoji": habit.emoji,
                    "currentStreak": habit.currentStreak,
                    "isCompletedToday": habit.isCompletedToday
                ] as [String: Any]
            },
            "identityTraits": identityTraits
        ]
    }
}

final class CoachService {
    static let shared = CoachService()
    private init() {}

    func sendMessage(content: String, history: [CoachMessage], habitContext: HabitContext?, conversationHistory: [[String: String]] = []) async throws -> CoachResponse {
        guard let session = try? await supabase.auth.session else {
            throw CoachError.networkError(URLError(.userAuthenticationRequired))
        }

        let recentHistory = Array(history.suffix(6))
        let url = URL(string: "\(Secrets.supabaseURL)/functions/v1/coach")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "message": content,
            "history": recentHistory.map { ["role": $0.role.rawValue, "content": $0.content] }
        ]
        if let context = habitContext {
            body["habitContext"] = context.toDictionary()
        }
        if !conversationHistory.isEmpty {
            body["conversationHistory"] = conversationHistory
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 402 {
            throw CoachError.rateLimitReached
        }

        return try JSONDecoder().decode(CoachResponse.self, from: data)
    }
}
