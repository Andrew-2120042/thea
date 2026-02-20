import SwiftUI

@MainActor
class IntentionsViewModel: ObservableObject {
    @Published var intentions: [Intention] = []
    @Published var isLoading = false

    func loadToday() async {
        isLoading = true
        defer { isLoading = false }
        do {
            if let daily = try await IntentionsService.shared.getTodaysIntentions() {
                intentions = daily.intentions
            }
        } catch {
            print("IntentionsViewModel: load failed — \(error)")
        }
    }

    func addIntention(text: String) {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        intentions.append(Intention(
            id: UUID().uuidString,
            text: text.trimmingCharacters(in: .whitespaces),
            completed: false,
            completedAt: nil,
            createdAt: Date()
        ))
    }

    func removeIntention(at index: Int) {
        guard intentions.indices.contains(index) else { return }
        intentions.remove(at: index)
    }

    func save(feeling: String?) async {
        do {
            try await IntentionsService.shared.saveIntentions(intentions: intentions, feeling: feeling)
        } catch {
            print("IntentionsViewModel: save failed — \(error)")
        }
    }

    func toggleCompletion(id: String) async {
        guard let idx = intentions.firstIndex(where: { $0.id == id }) else { return }
        let newState = !intentions[idx].completed
        intentions[idx].completed = newState
        intentions[idx].completedAt = newState ? Date() : nil

        // Persist
        do {
            if let daily = try await IntentionsService.shared.getTodaysIntentions() {
                var updated = daily
                if let di = updated.intentions.firstIndex(where: { $0.id == id }) {
                    updated.intentions[di].completed = newState
                    updated.intentions[di].completedAt = newState ? Date() : nil
                }
                try await IntentionsService.shared.updateIntentions(updated)
            }
        } catch {
            print("IntentionsViewModel: toggle failed — \(error)")
        }
    }
}
