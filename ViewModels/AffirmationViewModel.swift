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

        Task {
            do {
                currentAffirmation = try await AffirmationService.shared.getTodaysAffirmation(
                    mode: currentMode(settings: settings),
                    categories: settings.preferredCategories,
                    deviceId: settings.deviceId
                )
            } catch {
                self.error = error.localizedDescription
                currentAffirmation = AffirmationService.shared.getFallbackAffirmation(
                    mode: currentMode(settings: settings),
                    categories: settings.preferredCategories
                )
            }
            isLoading = false
        }
    }

    private func currentMode(settings: UserSettings) -> Affirmation.AffirmationMode {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour < 17 ? .morning : .night
    }

    func getCurrentGradient() -> LinearGradient {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return HypeColors.morningGradient
        case 12..<17: return HypeColors.afternoonGradient
        case 17..<21: return HypeColors.eveningGradient
        default: return HypeColors.nightGradient
        }
    }
}
