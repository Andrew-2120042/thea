import Foundation

struct UserActivity: Identifiable, Codable {
    let id: UUID
    let deviceId: String
    let affirmationId: UUID
    let hypeMessageId: UUID?
    let mode: String
    let completed: Bool
    let repeated: Bool
    let feelingAfter: String?
    let voiceLevelReached: Int
    let durationSeconds: Int
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case deviceId = "device_id"
        case affirmationId = "affirmation_id"
        case hypeMessageId = "hype_message_id"
        case mode
        case completed
        case repeated
        case feelingAfter = "feeling_after"
        case voiceLevelReached = "voice_level_reached"
        case durationSeconds = "duration_seconds"
        case createdAt = "created_at"
    }

    init(
        deviceId: String,
        affirmationId: UUID,
        hypeMessageId: UUID?,
        mode: String,
        feelingAfter: String?,
        voiceLevelReached: Int,
        durationSeconds: Int
    ) {
        self.id = UUID()
        self.deviceId = deviceId
        self.affirmationId = affirmationId
        self.hypeMessageId = hypeMessageId
        self.mode = mode
        self.completed = true
        self.repeated = false
        self.feelingAfter = feelingAfter
        self.voiceLevelReached = voiceLevelReached
        self.durationSeconds = durationSeconds
        self.createdAt = Date()
    }
}
