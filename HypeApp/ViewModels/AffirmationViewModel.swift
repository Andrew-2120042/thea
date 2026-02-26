import SwiftUI

@MainActor
class AffirmationViewModel: ObservableObject {
    @Published var currentAffirmation: Affirmation?
    @Published var allAffirmations: [Affirmation] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var voiceThreshold: Double = 60
    @Published var showPaywall = false

    func loadAllAffirmations() async {
        isLoading = true
        do {
            let affirmations: [Affirmation] = try await SupabaseService.shared.client
                .from("affirmations")
                .select()
                .eq("active", value: true)
                .order("order_index")
                .execute()
                .value
            allAffirmations = affirmations
        } catch {
            self.error = error.localizedDescription
            allAffirmations = AffirmationService.shared.fallbackAffirmations
        }
        isLoading = false
    }

    func loadAffirmation() {
        let settings = UserDefaults.standard.loadSettings()

        // Check paywall
        if !settings.isPremium && settings.freeAffirmationsUsed >= Constants.freeAffirmationLimit {
            showPaywall = true
            return
        }

        voiceThreshold = settings.voiceThreshold
        isLoading = true

        let mode = ThemeManager.themeForCurrentHour().affirmationMode

        Task {
            do {
                currentAffirmation = try await AffirmationService.shared.getTodaysAffirmation(
                    mode: mode,
                    categories: settings.preferredCategories,
                    deviceId: settings.deviceId
                )
            } catch {
                self.error = error.localizedDescription
                currentAffirmation = AffirmationService.shared.getFallbackAffirmation(
                    mode: mode,
                    categories: settings.preferredCategories
                )
            }
            isLoading = false
        }
    }
}
