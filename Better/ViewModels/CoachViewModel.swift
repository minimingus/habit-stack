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
    var showSoftPaywall = false

    private let storageKey = "coachMessages"
    private let memoryKey = "coach_conversation_history"
    private let usedTodayKey = "coachMessagesUsedToday"
    private let usedTodayDateKey = "coachMessagesUsedTodayDate"
    private let welcomeShownKey = "coachWelcomeShown"

    var messagesRemainingToday: Int { max(0, dailyLimit - messagesUsedToday) }

    init() {
        loadPersistedMessages()
        loadTodayUsage()
        if messages.isEmpty && !UserDefaults.standard.bool(forKey: welcomeShownKey) {
            Task { await insertWelcomeMessage() }
        }
    }

    private func insertWelcomeMessage() async {
        let traits = (UserDefaults.standard.stringArray(forKey: "selectedIdentityTraits") ?? [])
            .compactMap { IdentityTrait(rawValue: $0) }

        var habitNames: [String] = []
        if let userId = try? await supabase.auth.session.user.id {
            let habits = (try? await HabitService.shared.fetchTodayHabits(userId: userId)) ?? []
            habitNames = habits.map { $0.habit.name }
        }

        let welcome = buildWelcomeText(traits: traits, habitNames: habitNames)
        let msg = CoachMessage(role: .assistant, content: welcome)
        messages.append(msg)
        persistMessages()
        UserDefaults.standard.set(true, forKey: welcomeShownKey)
        PostHogSDK.shared.capture("coach_welcome_shown")
    }

    private func buildWelcomeText(traits: [IdentityTrait], habitNames: [String]) -> String {
        var parts: [String] = []

        if !traits.isEmpty {
            let traitNames = traits.map(\.displayName).joined(separator: " and ")
            parts.append("I see you're working on becoming more **\(traitNames)** — that's a powerful vision.")
        }

        if !habitNames.isEmpty {
            let names = habitNames.joined(separator: ", ")
            parts.append("You've set up some great habits: **\(names)**.")
        }

        if !habitNames.isEmpty {
            let first = habitNames[0]
            parts.append("Here's my Day 1 tip: pair **\(first)** with something you already do every day — like right after your morning coffee or brushing your teeth. Attaching new habits to existing routines makes them stick.")
        } else {
            parts.append("A great way to start: pick one small habit you can do right after something you already do every morning. Tiny wins build momentum.")
        }

        parts.append("How can I help you today?")

        let greeting = (traits.isEmpty && habitNames.isEmpty)
            ? "Welcome to your habit coach!"
            : "Welcome!"

        return "\(greeting) \(parts.joined(separator: " "))"
    }

    func sendMessage(_ text: String) async {
        let userMsg = CoachMessage(role: .user, content: text)
        messages.append(userMsg)
        persistMessages()
        isLoading = true
        errorMessage = nil

        do {
            let habitContext = await gatherHabitContext()
            let conversationMemory = loadConversationMemory()
            let response = try await CoachService.shared.sendMessage(
                content: text,
                history: Array(messages.suffix(6)),
                habitContext: habitContext,
                conversationHistory: conversationMemory
            )
            let assistantMsg = CoachMessage(role: .assistant, content: response.reply)
            messages.append(assistantMsg)
            persistMessages()
            saveConversationMemory()
            dailyLimit = response.messagesRemainingToday + messagesUsedToday + 1
            messagesUsedToday += 1
            saveTodayUsage()
            if !conversationMemory.isEmpty {
                PostHogSDK.shared.capture("coach_memory_used", properties: [
                    "history_length": conversationMemory.count / 2
                ])
            }
            PostHogSDK.shared.capture("coach_message_sent", properties: [
                "messages_today_count": messagesUsedToday
            ])
            if messagesUsedToday == 3 && !RevenueCatManager.shared.isProUser {
                PostHogSDK.shared.capture("paywall_shown", properties: ["trigger": "coach_3rd_message"])
                showSoftPaywall = true
            }
        } catch CoachError.rateLimitReached {
            messages.removeLast()
            persistMessages()
            showPaywall = true
        } catch {
            messages.removeLast()
            persistMessages()
            errorMessage = "Coach couldn't respond. Please try again."
            PostHogSDK.shared.capture("error_occurred", properties: ["source": "coach_send", "message": error.localizedDescription])
        }

        isLoading = false
    }

    func clearConversation() {
        messages = []
        persistMessages()
    }

    // MARK: - Habit Context

    private func gatherHabitContext() async -> HabitContext? {
        guard let userId = try? await supabase.auth.session.user.id else { return nil }

        do {
            let todayHabits = try await HabitService.shared.fetchTodayHabits(userId: userId)
            let streaks = try await StreakService.shared.fetchStreaks(userId: userId)
            let streakMap = Dictionary(uniqueKeysWithValues: streaks.map { ($0.habitId, $0) })

            let habitInfos = todayHabits.map { hw in
                let streak = streakMap[hw.habit.id]
                return HabitContext.HabitInfo(
                    name: hw.habit.name,
                    emoji: hw.habit.emoji,
                    currentStreak: streak?.currentStreak ?? 0,
                    isCompletedToday: hw.isCompleted
                )
            }

            let traits = (UserDefaults.standard.stringArray(forKey: "selectedIdentityTraits") ?? [])
                .compactMap { IdentityTrait(rawValue: $0) }
                .map(\.displayName)

            // Fetch identity votes for evidence
            let votes: [IdentityVote] = (try? await supabase
                .from("identity_votes")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value) ?? []

            let calendar = Calendar.current
            let now = Date()
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: now) ?? now

            let grouped = Dictionary(grouping: votes, by: { $0.identityStatement.lowercased().trimmingCharacters(in: .whitespaces) })
            let evidence = grouped.map { key, traitVotes in
                let firstDate = traitVotes.map(\.votedAt).min() ?? now
                let daysSince = max(0, calendar.dateComponents([.day], from: firstDate, to: now).day ?? 0)
                let lastWeek = traitVotes.filter { $0.votedAt >= weekAgo }.count
                let priorWeek = traitVotes.filter { $0.votedAt >= twoWeeksAgo && $0.votedAt < weekAgo }.count
                let displayName = traitVotes.first?.identityStatement ?? key
                return HabitContext.IdentityEvidence(
                    trait: displayName,
                    voteCount: traitVotes.count,
                    daysSinceFirstVote: daysSince,
                    lastWeekVotes: lastWeek,
                    priorWeekVotes: priorWeek
                )
            }
            .sorted { $0.voteCount > $1.voteCount }

            var context = HabitContext(habits: habitInfos, identityTraits: traits)
            context.identityEvidence = evidence
            return context
        } catch {
            return nil
        }
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

    // MARK: - Conversation Memory

    private func loadConversationMemory() -> [[String: String]] {
        guard let data = UserDefaults.standard.data(forKey: memoryKey),
              let memory = try? JSONDecoder().decode([[String: String]].self, from: data) else {
            return []
        }
        return memory
    }

    private func saveConversationMemory() {
        // Extract the last 5 exchanges (10 messages) as memory
        let exchanges = messages.suffix(10)
        let memory = exchanges.map { ["role": $0.role.rawValue, "content": $0.content] }
        guard let data = try? JSONEncoder().encode(memory) else { return }
        UserDefaults.standard.set(data, forKey: memoryKey)
    }
}
