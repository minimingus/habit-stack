import Foundation

struct ScorecardEntry: Codable, Identifiable {
    var id: UUID
    var behavior: String
    var rating: Rating?

    enum Rating: String, Codable, CaseIterable {
        case positive = "+"
        case neutral = "="
        case negative = "–"

        var label: String {
            switch self {
            case .positive: return "Casting a vote for who I want to become"
            case .neutral: return "Neither helps nor hurts"
            case .negative: return "Working against who I want to become"
            }
        }
    }
}

// MARK: - UserDefaults persistence

extension ScorecardEntry {
    static func load() -> [ScorecardEntry] {
        guard let data = UserDefaults.standard.data(forKey: "habitsScorecardEntries"),
              let entries = try? JSONDecoder().decode([ScorecardEntry].self, from: data)
        else { return [] }
        return entries
    }

    static func save(_ entries: [ScorecardEntry]) {
        let data = try? JSONEncoder().encode(entries)
        UserDefaults.standard.set(data, forKey: "habitsScorecardEntries")
    }
}
