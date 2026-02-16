import Foundation

struct Affirmation: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    let mode: AffirmationMode
    let category: String
    let active: Bool
    let orderIndex: Int?

    enum AffirmationMode: String, Codable, CaseIterable {
        case morning
        case night
    }

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case mode
        case category
        case active
        case orderIndex = "order_index"
    }
}
