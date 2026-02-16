import Foundation

struct UserSettings: Codable {
    var deviceId: String
    var name: String
    var affirmationsPerWeek: Int
    var preferredCategories: [String]
    var morningEnabled: Bool
    var nightEnabled: Bool
    var morningTime: String
    var nightTime: String
    var voiceThreshold: Double
    var currentStreak: Int
    var longestStreak: Int
    var lastMorningDate: Date?
    var lastNightDate: Date?
    var totalCompletions: Int
    var isPremium: Bool
    var onboardingCompleted: Bool
    var freeAffirmationsUsed: Int

    static var `default`: UserSettings {
        UserSettings(
            deviceId: UUID().uuidString,
            name: "",
            affirmationsPerWeek: 14,
            preferredCategories: ["confidence", "self-care", "boundaries"],
            morningEnabled: true,
            nightEnabled: true,
            morningTime: "07:00",
            nightTime: "22:00",
            voiceThreshold: 60,
            currentStreak: 0,
            longestStreak: 0,
            lastMorningDate: nil,
            lastNightDate: nil,
            totalCompletions: 0,
            isPremium: false,
            onboardingCompleted: false,
            freeAffirmationsUsed: 0
        )
    }
}
