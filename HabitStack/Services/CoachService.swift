import Foundation

enum CoachError: Error {
    case rateLimitReached
    case networkError(Error)
}

final class CoachService {
    static let shared = CoachService()
    private init() {}

    func sendMessage(content: String, history: [CoachMessage]) async throws -> CoachResponse {
        guard let session = try? await supabase.auth.session else {
            throw CoachError.networkError(URLError(.userAuthenticationRequired))
        }

        let recentHistory = Array(history.suffix(6))
        let url = URL(string: "\(Secrets.supabaseURL)/functions/v1/coach")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "message": content,
            "history": recentHistory.map { ["role": $0.role.rawValue, "content": $0.content] }
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 402 {
            throw CoachError.rateLimitReached
        }

        return try JSONDecoder().decode(CoachResponse.self, from: data)
    }
}
