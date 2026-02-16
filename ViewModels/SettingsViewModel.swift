import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var settings = UserSettings.default
    @Published var morningTime = Date()
    @Published var nightTime = Date()
    @Published var notificationsEnabled = false
    @Published var showDeleteConfirmation = false

    func loadSettings() {
        settings = UserDefaults.standard.loadSettings()
        morningTime = timeDate(from: settings.morningTime)
        nightTime = timeDate(from: settings.nightTime)
        checkNotificationStatus()
    }

    func saveSettings() {
        settings.morningTime = timeString(from: morningTime)
        settings.nightTime = timeString(from: nightTime)
        UserDefaults.standard.saveSettings(settings)

        // Re-schedule notifications
        if settings.morningEnabled {
            NotificationService.shared.scheduleMorningNotification(
                time: settings.morningTime,
                userName: settings.name
            )
        } else {
            NotificationService.shared.removeNotification(identifier: "morning-reminder")
        }

        if settings.nightEnabled {
            NotificationService.shared.scheduleNightNotification(
                time: settings.nightTime,
                userName: settings.name
            )
        } else {
            NotificationService.shared.removeNotification(identifier: "night-reminder")
        }

        HapticManager.notification(.success)
    }

    func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: Constants.onboardingCompletedKey)
        NotificationService.shared.removeAllNotifications()
    }

    func deleteAllData() {
        UserDefaults.standard.removeObject(forKey: Constants.userSettingsKey)
        UserDefaults.standard.set(false, forKey: Constants.onboardingCompletedKey)
        NotificationService.shared.removeAllNotifications()
    }

    private func checkNotificationStatus() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            notificationsEnabled = settings.authorizationStatus == .authorized
        }
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func timeDate(from string: String) -> Date {
        let parts = string.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else { return Date() }

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }
}
