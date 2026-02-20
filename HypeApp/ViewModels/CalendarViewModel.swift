import SwiftUI

@MainActor
class CalendarViewModel: ObservableObject {
    @Published var currentMonth = Date()
    @Published var activities: [UserActivity] = []
    @Published var completedDates: Set<String> = []
    @Published var isLoading = false
    @Published var currentStreak = 0
    @Published var longestStreak = 0
    @Published var totalCompletions = 0

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    func loadData() {
        let settings = UserDefaults.standard.loadSettings()
        currentStreak = settings.currentStreak
        longestStreak = settings.longestStreak
        totalCompletions = settings.totalCompletions

        loadActivities(deviceId: settings.deviceId)
    }

    func loadActivities(deviceId: String) {
        isLoading = true
        let calendar = Calendar.current
        guard let startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)),
              let endDate = calendar.date(byAdding: .month, value: 1, to: startDate) else {
            isLoading = false
            return
        }

        Task {
            let acts = try? await AffirmationService.shared.getActivities(
                deviceId: deviceId,
                from: startDate,
                to: endDate
            )

            if let acts = acts {
                activities = acts
                completedDates = Set(acts.map { dateFormatter.string(from: $0.createdAt) })
            }
            isLoading = false
        }
    }

    func isCompleted(date: Date) -> Bool {
        completedDates.contains(dateFormatter.string(from: date))
    }

    func previousMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = DateHelpers.shared.previousMonth(from: currentMonth)
        }
        let settings = UserDefaults.standard.loadSettings()
        loadActivities(deviceId: settings.deviceId)
    }

    func nextMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = DateHelpers.shared.nextMonth(from: currentMonth)
        }
        let settings = UserDefaults.standard.loadSettings()
        loadActivities(deviceId: settings.deviceId)
    }

    var daysInCurrentMonth: [Date] {
        DateHelpers.shared.daysInMonth(for: currentMonth)
    }

    var firstWeekdayOffset: Int {
        DateHelpers.shared.firstWeekdayOffset(for: currentMonth)
    }

    var monthYearString: String {
        DateHelpers.shared.monthYearString(for: currentMonth)
    }
}
