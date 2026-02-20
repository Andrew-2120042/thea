import Foundation

struct DailyJournal: Codable, Identifiable {
    let id: UUID
    let deviceId: String
    let date: String          // "YYYY-MM-DD"
    var entry: String
    let prompt: String?
    let feeling: String?
    let wordCount: Int
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, date, entry, prompt, feeling
        case deviceId  = "device_id"
        case wordCount = "word_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
