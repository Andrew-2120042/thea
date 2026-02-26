import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    @Published var greeting = ""
    @Published var userName = ""
    @Published var morningCompleted = false
    @Published var nightCompleted = false
    @Published var currentStreak = 0

    func loadUserData() {
        let settings = UserDefaults.standard.loadSettings()
        userName = settings.name
        currentStreak = settings.currentStreak
        checkTodayCompletions(settings: settings)
        updateGreeting()
    }

    private func updateGreeting() {
        greeting = ThemeManager.themeForCurrentHour().greeting
    }

    private func checkTodayCompletions(settings: UserSettings) {
        morningCompleted = StreakService.shared.isCompletedToday(lastDate: settings.lastMorningDate)
        nightCompleted = StreakService.shared.isCompletedToday(lastDate: settings.lastNightDate)
    }

    var isAllCompletedToday: Bool {
        #if DEBUG
        return false
        #else
        return morningCompleted && nightCompleted
        #endif
    }

    var checkInText: String {
        if isAllCompletedToday {
            return "Completed today ✓"
        } else if morningCompleted {
            return "Night check-in"
        } else {
            return "Check in"
        }
    }

    var streakAtRisk: Bool {
        let settings = UserDefaults.standard.loadSettings()
        return StreakService.shared.streakAtRisk(lastDate: settings.lastMorningDate)
    }
}
