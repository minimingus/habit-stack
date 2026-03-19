import Foundation
import Observation
import PostHog

@Observable
final class CoachViewModel {
    var messages: [CoachMessage] = []
    var isLoading = false
    var messagesUsedToday: Int = 0
    var dailyLimit: Int = 5
    var errorMessage: String?
    var showPaywall = false

    private let storageKey = "coachMessages"
    private let usedTodayKey = "coachMessagesUsedToday"
    private let usedTodayDateKey = "coachMessagesUsedTodayDate"

    var messagesRemainingToday: Int { max(0, dailyLimit - messagesUsedToday) }

    init() {
        loadPersistedMessages()
        loadTodayUsage()
    }

    func sendMessage(_ text: String) async {
        let userMsg = CoachMessage(role: .user, content: text)
        messages.append(userMsg)
        persistMessages()
        isLoading = true
        errorMessage = nil

        do {
            let response = try await CoachService.shared.sendMessage(
                content: text,
                history: Array(messages.suffix(6))
            )
            let assistantMsg = CoachMessage(role: .assistant, content: response.reply)
            messages.append(assistantMsg)
            persistMessages()
            dailyLimit = response.messagesRemainingToday + messagesUsedToday + 1
            messagesUsedToday += 1
            saveTodayUsage()
            PostHogSDK.shared.capture("coach_message_sent", properties: [
                "messages_today_count": messagesUsedToday
            ])
        } catch CoachError.rateLimitReached {
            messages.removeLast()
            persistMessages()
            showPaywall = true
        } catch {
            messages.removeLast()
            persistMessages()
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func clearConversation() {
        messages = []
        persistMessages()
    }

    // MARK: - Persistence

    private func loadPersistedMessages() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([CoachMessage].self, from: data) else { return }
        // Keep only last 50 messages
        messages = Array(decoded.suffix(50))
    }

    private func persistMessages() {
        let toSave = Array(messages.suffix(50))
        guard let data = try? JSONEncoder().encode(toSave) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func loadTodayUsage() {
        let storedDate = UserDefaults.standard.string(forKey: usedTodayDateKey) ?? ""
        let today = ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: Date()))
        if storedDate == today {
            messagesUsedToday = UserDefaults.standard.integer(forKey: usedTodayKey)
        } else {
            messagesUsedToday = 0
            saveTodayUsage()
        }
    }

    private func saveTodayUsage() {
        let today = ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: Date()))
        UserDefaults.standard.set(today, forKey: usedTodayDateKey)
        UserDefaults.standard.set(messagesUsedToday, forKey: usedTodayKey)
    }
}
