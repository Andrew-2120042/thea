import Foundation

struct Intention: Codable, Identifiable {
    let id: String
    var text: String
    var completed: Bool
    var completedAt: Date?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, text, completed
        case completedAt = "completed_at"
        case createdAt = "created_at"
    }
}

struct DailyIntentions: Codable, Identifiable {
    let id: UUID
    let deviceId: String
    let date: String          // "YYYY-MM-DD" stored as text
    var intentions: [Intention]
    let feeling: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, date, intentions, feeling
        case deviceId  = "device_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
