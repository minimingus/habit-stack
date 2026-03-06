import Foundation
import Observation

@Observable
final class CoachViewModel {
    var messages: [CoachMessage] = []
    var isLoading = false
    var messagesRemainingToday: Int = 5
    var errorMessage: String?
    var showPaywall = false

    func sendMessage(_ text: String) async {
        let userMsg = CoachMessage(role: .user, content: text)
        messages.append(userMsg)
        isLoading = true
        errorMessage = nil

        do {
            let response = try await CoachService.shared.sendMessage(
                content: text,
                history: Array(messages.suffix(6))
            )
            let assistantMsg = CoachMessage(role: .assistant, content: response.reply)
            messages.append(assistantMsg)
            messagesRemainingToday = response.messagesRemainingToday
        } catch CoachError.rateLimitReached {
            messages.removeLast() // Remove the user message that failed
            showPaywall = true
        } catch {
            messages.removeLast()
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
