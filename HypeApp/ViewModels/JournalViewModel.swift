import SwiftUI
import PhotosUI

@MainActor
class JournalViewModel: ObservableObject {
    @Published var entry: String = ""
    @Published var currentPrompt: String = ""
    @Published var isLoading = false
    @Published var attachedPhotos: [String] = [] // URLs of uploaded photos
    @Published var isUploadingPhoto = false
    var deviceId: String {
        let key = "hype_device_id"
        if let stored = UserDefaults.standard.string(forKey: key) { return stored }
        let new = UUID().uuidString
        UserDefaults.standard.set(new, forKey: key)
        return new
    }

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
                attachedPhotos = journal.photoUrls ?? []
            } else {
                currentPrompt = promptFor(feeling)
                attachedPhotos = []
            }
        } catch {
            currentPrompt = promptFor(feeling)
            attachedPhotos = []
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
            try await JournalService.shared.saveJournal(entry: entry, prompt: currentPrompt, feeling: feeling, photoUrls: attachedPhotos.isEmpty ? nil : attachedPhotos)
        } catch {
            print("JournalViewModel: save failed — \(error)")
        }
    }

    func attachPhoto(_ item: PhotosPickerItem) async {
        isUploadingPhoto = true
        do {
            let journalId = deviceId + "_" + ISO8601DateFormatter().string(from: Date())
            let photoUrl = try await PhotoStorageService.shared.uploadPhoto(
                item: item,
                journalId: journalId
            )
            attachedPhotos.append(photoUrl)
        } catch {
            print("Failed to upload photo: \(error)")
        }
        isUploadingPhoto = false
    }

    func removePhoto(at index: Int) async {
        let url = attachedPhotos[index]
        do {
            try await PhotoStorageService.shared.deletePhoto(url: url)
            attachedPhotos.remove(at: index)
        } catch {
            print("Failed to delete photo: \(error)")
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
