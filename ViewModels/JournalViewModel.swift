import SwiftUI

@MainActor
class JournalViewModel: ObservableObject {
    @Published var entry: String = ""
    @Published var currentPrompt: String = ""
    @Published var isLoading = false

    private let defaultPrompts = [
        "What's one thing you're grateful for today?",
        "What did you learn today?",
        "What challenged you today?",
        "What surprised you today?",
        "What made you smile today?",
        "What would you do differently tomorrow?",
        "What's one small win from today?"
    ]

    private let feelingPrompts: [String: [String]] = [
        "in tune": [
            "What made today amazing?",
            "What accomplishment are you most proud of?",
            "What energised you the most today?"
        ],
        "shift": [
            "What went well today?",
            "What are you grateful for right now?",
            "What surprised you today?"
        ],
        "same": [
            "What's one small win from today?",
            "What kept you going today?",
            "What would you tell a friend about today?"
        ]
    ]

    func load(feeling: String?) async {
        isLoading = true
        defer { isLoading = false }
        do {
            if let journal = try await JournalService.shared.getTodaysJournal() {
                entry = journal.entry
                currentPrompt = journal.prompt ?? promptFor(feeling)
            } else {
                currentPrompt = promptFor(feeling)
            }
        } catch {
            currentPrompt = promptFor(feeling)
            print("JournalViewModel: load failed — \(error)")
        }
    }

    func rotatePrompt() {
        let others = defaultPrompts.filter { $0 != currentPrompt }
        currentPrompt = others.randomElement() ?? defaultPrompts[0]
    }

    func save(feeling: String?) async {
        guard !entry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        do {
            try await JournalService.shared.saveJournal(entry: entry, prompt: currentPrompt, feeling: feeling)
        } catch {
            print("JournalViewModel: save failed — \(error)")
        }
    }

    private func promptFor(_ feeling: String?) -> String {
        guard let f = feeling?.lowercased() else { return defaultPrompts.randomElement()! }
        for (key, prompts) in feelingPrompts {
            if f.contains(key) { return prompts.randomElement()! }
        }
        return defaultPrompts.randomElement()!
    }
}
