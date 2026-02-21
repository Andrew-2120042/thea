import SwiftUI

enum JournalToolbarAction: Identifiable {
    case emoji
    case photo
    case draw
    case voice
    case bulletList
    case numberedList
    case keyboard

    var id: String {
        switch self {
        case .emoji: return "emoji"
        case .photo: return "photo"
        case .draw: return "draw"
        case .voice: return "voice"
        case .bulletList: return "bulletList"
        case .numberedList: return "numberedList"
        case .keyboard: return "keyboard"
        }
    }

    var icon: String {
        switch self {
        case .emoji: return "face.smiling"
        case .photo: return "photo"
        case .draw: return "scribble"
        case .voice: return "mic.fill"
        case .bulletList: return "list.bullet"
        case .numberedList: return "list.number"
        case .keyboard: return "keyboard.chevron.compact.down"
        }
    }
}

enum JournalListType {
    case none
    case bullet
    case numbered
}
