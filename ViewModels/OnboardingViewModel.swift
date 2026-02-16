import SwiftUI

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentStep = 0
    @Published var userName = ""
    @Published var affirmationsPerWeek = 14
    @Published var selectedCategories: Set<String> = ["confidence", "self-care", "boundaries"]
    @Published var morningEnabled = true
    @Published var nightEnabled = true
    @Published var morningTime = Date()
    @Published var nightTime = Date()
    @Published var voiceThreshold: Double = 60
    @Published var notificationsGranted = false
    @Published var microphoneGranted = false
    @Published var availableCategories: [AffirmationCategory] = AffirmationCategory.defaults
    @Published var isLoadingCategories = false

    let totalSteps = 8

    // Step indices
    enum Step: Int {
        case welcome = 0
        case howItWorks = 1
        case getHype = 2
        case name = 3
        case frequency = 4
        case category = 5
        case voiceSetup = 6
        case notifications = 7
    }

    init() {
        // Set default times
        var morningComponents = DateComponents()
        morningComponents.hour = 7
        morningComponents.minute = 0
        morningTime = Calendar.current.date(from: morningComponents) ?? Date()

        var nightComponents = DateComponents()
        nightComponents.hour = 22
        nightComponents.minute = 0
        nightTime = Calendar.current.date(from: nightComponents) ?? Date()
    }

    // MARK: - Navigation
    func nextStep() {
        if currentStep < totalSteps - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep += 1
            }
            HapticManager.selection()
        }
    }

    func prevStep() {
        if currentStep > 0 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep -= 1
            }
        }
    }

    // MARK: - Category Toggle
    func toggleCategory(_ categoryName: String) {
        if selectedCategories.contains(categoryName) {
            if selectedCategories.count > 1 {  // Always keep at least one
                selectedCategories.remove(categoryName)
            }
        } else {
            selectedCategories.insert(categoryName)
        }
        HapticManager.selection()
    }

    // MARK: - Load Categories
    func loadCategories() {
        isLoadingCategories = true
        Task {
            do {
                let cats = try await AffirmationService.shared.getCategories()
                availableCategories = cats.isEmpty ? AffirmationCategory.defaults : cats
            } catch {
                availableCategories = AffirmationCategory.defaults
            }
            isLoadingCategories = false
        }
    }

    // MARK: - Request Microphone
    func requestMicrophone() async {
        microphoneGranted = await VoiceService.requestPermission()
    }

    // MARK: - Request Notifications
    func requestNotifications() async {
        notificationsGranted = await NotificationService.shared.requestPermission()
    }

    // MARK: - Complete Onboarding
    func completeOnboarding() {
        var settings = UserSettings.default
        settings.name = userName.trimmed.isEmpty ? "Queen" : userName.trimmed
        settings.affirmationsPerWeek = affirmationsPerWeek
        settings.preferredCategories = Array(selectedCategories)
        settings.morningEnabled = morningEnabled
        settings.nightEnabled = nightEnabled
        settings.morningTime = timeString(from: morningTime)
        settings.nightTime = timeString(from: nightTime)
        settings.voiceThreshold = voiceThreshold
        settings.onboardingCompleted = true

        UserDefaults.standard.saveSettings(settings)

        // Schedule notifications
        if notificationsGranted {
            if morningEnabled {
                NotificationService.shared.scheduleMorningNotification(
                    time: settings.morningTime,
                    userName: settings.name
                )
            }
            if nightEnabled {
                NotificationService.shared.scheduleNightNotification(
                    time: settings.nightTime,
                    userName: settings.name
                )
            }
        }

        HapticManager.successCelebration()

        UserDefaults.standard.set(true, forKey: Constants.onboardingCompletedKey)
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
