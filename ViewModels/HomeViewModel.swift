import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    @Published var greeting = ""
    @Published var userName = ""
    @Published var morningCompleted = false
    @Published var nightCompleted = false
    @Published var currentStreak = 0
    @Published var showMorning = true  // Which mode to show

    func loadUserData() {
        let settings = UserDefaults.standard.loadSettings()
        userName = settings.name
        currentStreak = settings.currentStreak
        checkTodayCompletions(settings: settings)
        updateGreeting()
        updateMode()
    }

    private func updateGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            greeting = "Good Morning"
        case 12..<17:
            greeting = "Good Afternoon"
        case 17..<21:
            greeting = "Good Evening"
        default:
            greeting = "Good Night"
        }
    }

    private func updateMode() {
        let hour = Calendar.current.component(.hour, from: Date())
        showMorning = hour < 17  // Morning/afternoon shows morning affirmation
    }

    private func checkTodayCompletions(settings: UserSettings) {
        morningCompleted = StreakService.shared.isCompletedToday(lastDate: settings.lastMorningDate)
        nightCompleted = StreakService.shared.isCompletedToday(lastDate: settings.lastNightDate)
    }

    func getCurrentGradient() -> LinearGradient {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return HypeColors.morningGradient
        case 12..<17:
            return HypeColors.afternoonGradient
        case 17..<21:
            return HypeColors.eveningGradient
        default:
            return HypeColors.nightGradient
        }
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

    var currentMode: Affirmation.AffirmationMode {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour < 17 ? .morning : .night
    }

    var streakAtRisk: Bool {
        let settings = UserDefaults.standard.loadSettings()
        return StreakService.shared.streakAtRisk(lastDate: settings.lastMorningDate)
    }
}
