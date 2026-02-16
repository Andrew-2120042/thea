import UserNotifications

class NotificationService {
    static let shared = NotificationService()

    // MARK: - Request Permission
    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    // MARK: - Schedule Morning Notification
    func scheduleMorningNotification(time: String, userName: String = "") {
        removeNotification(identifier: "morning-reminder")

        let content = UNMutableNotificationContent()
        let name = userName.isEmpty ? "queen" : userName
        content.title = "Good morning \(name)! 👑"
        content.body = "Your daily affirmation is ready. Speak it loud."
        content.sound = .default

        guard let components = parseTime(time) else { return }
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "morning-reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("NotificationService: Morning notification error: \(error)")
            }
        }
    }

    // MARK: - Schedule Night Notification
    func scheduleNightNotification(time: String, userName: String = "") {
        removeNotification(identifier: "night-reminder")

        let content = UNMutableNotificationContent()
        let name = userName.isEmpty ? "queen" : userName
        content.title = "Before you sleep, \(name)... 🌙"
        content.body = "Take 30 seconds for yourself. You deserve it."
        content.sound = .default

        guard let components = parseTime(time) else { return }
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "night-reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("NotificationService: Night notification error: \(error)")
            }
        }
    }

    // MARK: - Schedule Streak Reminder
    func scheduleStreakReminder(streak: Int) {
        guard streak > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Don't break your \(streak)-day streak! 🔥"
        content.body = "Your affirmation is waiting. Keep the momentum going."
        content.sound = .default

        // Schedule for 8pm if they haven't completed today
        var components = DateComponents()
        components.hour = 20
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "streak-reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Remove Notification
    func removeNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Parse Time String "HH:MM"
    private func parseTime(_ time: String) -> DateComponents? {
        let parts = time.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else { return nil }

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return components
    }
}
