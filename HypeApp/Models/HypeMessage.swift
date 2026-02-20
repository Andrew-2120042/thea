import Foundation

struct HypeMessage: Identifiable, Codable {
    let id: UUID
    let text: String
    let mode: String
    let active: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case mode
        case active
    }
}
