import Foundation

class StreakService {
    static let shared = StreakService()

    // MARK: - Calculate Streak
    func calculateStreak(lastDate: Date?, currentStreak: Int) -> Int {
        guard let lastDate = lastDate else { return 1 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let last = calendar.startOfDay(for: lastDate)

        let days = calendar.dateComponents([.day], from: last, to: today).day ?? 0

        switch days {
        case 0:
            return currentStreak  // Same day, no change
        case 1:
            return currentStreak + 1  // Consecutive day
        default:
            return 1  // Streak broken, restart
        }
    }

    // MARK: - Update Streak in UserSettings
    @discardableResult
    func updateStreak(
        mode: Affirmation.AffirmationMode,
        settings: inout UserSettings
    ) -> Int {
        let newStreak = calculateStreak(
            lastDate: mode == .morning ? settings.lastMorningDate : settings.lastNightDate,
            currentStreak: settings.currentStreak
        )

        settings.currentStreak = newStreak
        settings.longestStreak = max(settings.longestStreak, newStreak)

        if mode == .morning {
            settings.lastMorningDate = Date()
        } else {
            settings.lastNightDate = Date()
        }

        settings.totalCompletions += 1
        settings.freeAffirmationsUsed += 1

        return newStreak
    }

    // MARK: - Check If Completed Today
    func isCompletedToday(lastDate: Date?) -> Bool {
        guard let lastDate = lastDate else { return false }
        return Calendar.current.isDate(lastDate, inSameDayAs: Date())
    }

    // MARK: - Get Streak Status
    func streakAtRisk(lastDate: Date?) -> Bool {
        guard let lastDate = lastDate else { return false }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let last = calendar.startOfDay(for: lastDate)
        let days = calendar.dateComponents([.day], from: last, to: today).day ?? 0
        return days == 1 // Completed yesterday, haven't done today yet
    }
}
