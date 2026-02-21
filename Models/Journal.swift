import Foundation

struct DailyJournal: Codable, Identifiable {
    let id: UUID
    let deviceId: String
    let date: String          // "YYYY-MM-DD"
    var entry: String
    let prompt: String?
    let feeling: String?
    let wordCount: Int
    var photoUrls: [String]?  // Array of Supabase Storage URLs
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, date, entry, prompt, feeling
        case deviceId  = "device_id"
        case wordCount = "word_count"
        case photoUrls = "photo_urls"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(deviceId, forKey: .deviceId)
        try container.encode(date, forKey: .date)
        try container.encode(entry, forKey: .entry)
        try container.encodeIfPresent(prompt, forKey: .prompt)
        try container.encodeIfPresent(feeling, forKey: .feeling)
        try container.encode(wordCount, forKey: .wordCount)
        // Only include photoUrls if not nil (avoids error when column doesn't exist)
        if photoUrls != nil {
            try container.encode(photoUrls, forKey: .photoUrls)
        }
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
