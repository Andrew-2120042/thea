import SwiftUI

@MainActor
class HypeViewModel: ObservableObject {
    @Published var hypeMessage: HypeMessage?
    @Published var currentStreak = 0
    @Published var showRetryModal = false
    @Published var isLoading = false

    func loadHypeMessage(mode: String) {
        isLoading = true
        Task {
            do {
                hypeMessage = try await AffirmationService.shared.getRandomHypeMessage(mode: mode)
            } catch {
                hypeMessage = HypeMessage(id: UUID(), text: "YES QUEEN! You're unstoppable! 🔥", mode: mode, active: true)
            }
            isLoading = false
        }
    }

    func updateStreak(for affirmation: Affirmation?) {
        guard let affirmation = affirmation else { return }
        var settings = UserDefaults.standard.loadSettings()
        let newStreak = StreakService.shared.updateStreak(mode: affirmation.mode, settings: &settings)
        currentStreak = newStreak
        UserDefaults.standard.saveSettings(settings)

        // Save activity to Supabase
        let activity = UserActivity(
            deviceId: settings.deviceId,
            affirmationId: affirmation.id,
            hypeMessageId: hypeMessage?.id,
            mode: affirmation.mode.rawValue,
            feelingAfter: nil,
            voiceLevelReached: 70,
            durationSeconds: 30
        )

        Task {
            try? await AffirmationService.shared.saveActivity(activity)
        }
    }

    func saveFeeling(_ feeling: String, for affirmation: Affirmation?) {
        guard let affirmation = affirmation else { return }
        let settings = UserDefaults.standard.loadSettings()

        let activity = UserActivity(
            deviceId: settings.deviceId,
            affirmationId: affirmation.id,
            hypeMessageId: hypeMessage?.id,
            mode: affirmation.mode.rawValue,
            feelingAfter: feeling,
            voiceLevelReached: 70,
            durationSeconds: 30
        )

        Task {
            try? await AffirmationService.shared.saveActivity(activity)
        }
    }
}
