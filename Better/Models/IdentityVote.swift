import Foundation

struct IdentityVote: Codable, Identifiable {
    var id: UUID
    var habitId: UUID
    var userId: UUID
    var identityStatement: String
    var votedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case habitId = "habit_id"
        case userId = "user_id"
        case identityStatement = "identity_statement"
        case votedAt = "voted_at"
    }
}
