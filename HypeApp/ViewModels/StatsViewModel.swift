import SwiftUI

@MainActor
class StatsViewModel: ObservableObject {
    @Published var currentStreak = 0
    @Published var longestStreak = 0
    @Published var thisWeekAffirmations = 0
    @Published var thisWeekIntentions = 0
    @Published var thisWeekIntentionsCompleted = 0
    @Published var thisWeekJournals = 0
    @Published var calendarData: [String: Bool] = [:] // date: completed
    @Published var moodData: [String: Int] = [:] // mood: count
    @Published var topIntentions: [(text: String, count: Int)] = []
    @Published var isLoading = false
    @Published var selectedTimePeriod: TimePeriod = .week

    var deviceId: String {
        let key = "hype_device_id"
        if let stored = UserDefaults.standard.string(forKey: key) { return stored }
        let new = UUID().uuidString
        UserDefaults.standard.set(new, forKey: key)
        return new
    }

    enum TimePeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case all = "All Time"
    }

    func loadStats() async {
        isLoading = true

        // Calculate current streak
        await calculateStreak()

        // Load this week's stats
        await loadWeeklyStats()

        // Load calendar data (last 60 days)
        await loadCalendarData()

        // Load mood trends
        await loadMoodData()

        // Load top intentions
        await loadTopIntentions()

        isLoading = false
    }

    private func calculateStreak() async {
        // Fetch user_activity sorted by date DESC
        do {
            let activities: [UserActivity] = try await SupabaseService.shared.client
                .from("user_activity")
                .select()
                .eq("device_id", value: deviceId)
                .order("created_at", ascending: false)
                .execute()
                .value

            // Group by date and calculate streak
            var streak = 0
            var longestStreakCount = 0
            var currentStreakCount = 0
            var lastDate: Date?

            let calendar = Calendar.current

            for activity in activities {
                let activityDate = calendar.startOfDay(for: activity.createdAt)

                if let last = lastDate {
                    let dayDiff = calendar.dateComponents([.day], from: activityDate, to: last).day ?? 0

                    if dayDiff == 1 {
                        currentStreakCount += 1
                    } else if dayDiff > 1 {
                        longestStreakCount = max(longestStreakCount, currentStreakCount)
                        currentStreakCount = 1
                    }
                } else {
                    currentStreakCount = 1
                }

                lastDate = activityDate
            }

            // Check if streak is current (last activity was today or yesterday)
            if let last = lastDate {
                let today = calendar.startOfDay(for: Date())
                let daysSinceLastActivity = calendar.dateComponents([.day], from: last, to: today).day ?? 0

                if daysSinceLastActivity <= 1 {
                    streak = currentStreakCount
                } else {
                    streak = 0
                }
            }

            currentStreak = streak
            longestStreak = max(longestStreakCount, currentStreakCount)

        } catch {
            print("Error calculating streak: \(error)")
        }
    }

    private func loadWeeklyStats() async {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!

        do {
            // Affirmations this week
            let activities: [UserActivity] = try await SupabaseService.shared.client
                .from("user_activity")
                .select()
                .eq("device_id", value: deviceId)
                .gte("created_at", value: weekAgo.ISO8601Format())
                .execute()
                .value

            thisWeekAffirmations = activities.count

            // Intentions this week
            let intentions: [DailyIntentions] = try await SupabaseService.shared.client
                .from("daily_intentions")
                .select()
                .eq("device_id", value: deviceId)
                .gte("created_at", value: weekAgo.ISO8601Format())
                .execute()
                .value

            thisWeekIntentions = intentions.count

            let completedCount = intentions.reduce(0) { total, daily in
                total + daily.intentions.filter { $0.completed }.count
            }
            thisWeekIntentionsCompleted = completedCount

            // Journals this week
            let journals: [DailyJournal] = try await SupabaseService.shared.client
                .from("daily_journal")
                .select()
                .eq("device_id", value: deviceId)
                .gte("created_at", value: weekAgo.ISO8601Format())
                .execute()
                .value

            thisWeekJournals = journals.count

        } catch {
            print("Error loading weekly stats: \(error)")
        }
    }

    private func loadCalendarData() async {
        let calendar = Calendar.current
        let sixtyDaysAgo = calendar.date(byAdding: .day, value: -60, to: Date())!

        do {
            let activities: [UserActivity] = try await SupabaseService.shared.client
                .from("user_activity")
                .select()
                .eq("device_id", value: deviceId)
                .gte("created_at", value: sixtyDaysAgo.ISO8601Format())
                .execute()
                .value

            // Group by date
            var dateSet = Set<String>()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            for activity in activities {
                let dateString = dateFormatter.string(from: activity.createdAt)
                dateSet.insert(dateString)
            }

            // Create calendar data
            var data: [String: Bool] = [:]
            for i in 0..<60 {
                if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                    let dateString = dateFormatter.string(from: date)
                    data[dateString] = dateSet.contains(dateString)
                }
            }

            calendarData = data

        } catch {
            print("Error loading calendar data: \(error)")
        }
    }

    private func loadMoodData() async {
        // Load from user_activity or feeling selections
        // Placeholder for now
        moodData = [
            "Calm": 3,
            "Joy": 2,
            "Energized": 4
        ]
    }

    private func loadTopIntentions() async {
        do {
            let intentions: [DailyIntentions] = try await SupabaseService.shared.client
                .from("daily_intentions")
                .select()
                .eq("device_id", value: deviceId)
                .execute()
                .value

            // Count all intention texts
            var intentionCounts: [String: Int] = [:]

            for daily in intentions {
                for intention in daily.intentions {
                    let text = intention.text.lowercased()
                    intentionCounts[text, default: 0] += 1
                }
            }

            // Sort by count and take top 5
            topIntentions = intentionCounts
                .sorted { $0.value > $1.value }
                .prefix(5)
                .map { (text: $0.key.capitalized, count: $0.value) }

        } catch {
            print("Error loading top intentions: \(error)")
        }
    }
}
