import Foundation

struct AffirmationCategory: Identifiable, Codable {
    let id: UUID
    let name: String
    let displayName: String
    let description: String
    let icon: String
    let active: Bool
    let orderIndex: Int

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case displayName = "display_name"
        case description
        case icon
        case active
        case orderIndex = "order_index"
    }

    // Default categories for offline/fallback use
    static let defaults: [AffirmationCategory] = [
        AffirmationCategory(id: UUID(), name: "confidence", displayName: "Confidence", description: "Build unshakeable self-belief", icon: "💪", active: true, orderIndex: 0),
        AffirmationCategory(id: UUID(), name: "self-care", displayName: "Self-Care", description: "Nurture your mind and body", icon: "🌸", active: true, orderIndex: 1),
        AffirmationCategory(id: UUID(), name: "boundaries", displayName: "Boundaries", description: "Honor your needs", icon: "🛡️", active: true, orderIndex: 2),
        AffirmationCategory(id: UUID(), name: "abundance", displayName: "Abundance", description: "Attract prosperity and joy", icon: "✨", active: true, orderIndex: 3),
        AffirmationCategory(id: UUID(), name: "relationships", displayName: "Relationships", description: "Cultivate meaningful connections", icon: "💕", active: true, orderIndex: 4),
        AffirmationCategory(id: UUID(), name: "career", displayName: "Career", description: "Step into your professional power", icon: "🚀", active: true, orderIndex: 5),
        AffirmationCategory(id: UUID(), name: "healing", displayName: "Healing", description: "Release what no longer serves you", icon: "🌿", active: true, orderIndex: 6),
        AffirmationCategory(id: UUID(), name: "gratitude", displayName: "Gratitude", description: "Appreciate the beauty around you", icon: "🙏", active: true, orderIndex: 7),
    ]
}
