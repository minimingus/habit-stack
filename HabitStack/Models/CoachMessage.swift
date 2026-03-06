import Foundation

struct CoachMessage: Identifiable, Codable {
    var id: UUID
    var role: Role
    var content: String
    var timestamp: Date

    enum Role: String, Codable {
        case user, assistant
    }

    init(id: UUID = UUID(), role: Role, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

struct CoachResponse: Decodable {
    let reply: String
    let messagesRemainingToday: Int

    enum CodingKeys: String, CodingKey {
        case reply
        case messagesRemainingToday = "messagesRemainingToday"
    }
}
