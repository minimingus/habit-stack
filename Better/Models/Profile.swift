import Foundation

struct Profile: Codable, Identifiable {
    var id: UUID
    var name: String?
    var xpTotal: Int
    var level: Int
    var streakShields: Int
    var plan: Plan
    var createdAt: Date

    enum Plan: String, Codable {
        case free, pro
    }

    enum CodingKeys: String, CodingKey {
        case id, name, level, plan
        case xpTotal = "xp_total"
        case streakShields = "streak_shields"
        case createdAt = "created_at"
    }
}
