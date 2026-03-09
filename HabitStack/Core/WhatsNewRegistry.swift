import SwiftUI

struct WhatsNewFeature: Identifiable {
    let id: String       // stable slug — never change after release
    let emoji: String
    let title: String
    let body: String
}

/// Add one entry here whenever you ship a new user-facing feature.
/// That's the only file you need to touch — the sheet appears automatically.
enum WhatsNewRegistry {
    static let all: [WhatsNewFeature] = [
        WhatsNewFeature(
            id: "v1-hold-complete",
            emoji: "⏳",
            title: "Hold to Complete",
            body: "Press and hold the circle next to any habit to mark it done. Release early to cancel."
        ),
        WhatsNewFeature(
            id: "v1-count-habits",
            emoji: "🔢",
            title: "Count-Based Habits",
            body: "Track habits with a target count (e.g. 8 glasses of water). Tap + to increment, or hold the circle to complete in one go."
        ),
        WhatsNewFeature(
            id: "v1-habit-pause",
            emoji: "⏸️",
            title: "Habit Pause",
            body: "Going on holiday or feeling under the weather? Long-press any habit → Pause. Your streak stays protected while it's paused."
        ),
        WhatsNewFeature(
            id: "v1-achievements",
            emoji: "🏆",
            title: "Achievements",
            body: "Earn streak milestone badges (7, 21, 66, 100 days) and a Perfect Day badge. Find them in Analytics."
        ),
        WhatsNewFeature(
            id: "v1-weekly-reflection",
            emoji: "📋",
            title: "Weekly Reflection",
            body: "Once a week the app prompts you to reflect on what's working and what to adjust. Honest reflection is the fastest way to improve."
        ),
    ]
}

final class WhatsNewService {
    private let seenKey = "whatsNew.seen"

    func unseenFeatures() -> [WhatsNewFeature] {
        let seen = Set(UserDefaults.standard.stringArray(forKey: seenKey) ?? [])
        return WhatsNewRegistry.all.filter { !seen.contains($0.id) }
    }

    func markAllSeen(_ features: [WhatsNewFeature]) {
        var seen = Set(UserDefaults.standard.stringArray(forKey: seenKey) ?? [])
        features.forEach { seen.insert($0.id) }
        UserDefaults.standard.set(Array(seen), forKey: seenKey)
    }

    /// Call on fresh install so first-time users don't see a wall of
    /// "new" features that are actually the baseline experience.
    func bootstrapIfNeeded() {
        let key = "whatsNew.bootstrapped"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        markAllSeen(WhatsNewRegistry.all)
        UserDefaults.standard.set(true, forKey: key)
    }
}
