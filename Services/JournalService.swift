import Foundation

class JournalService {
    static let shared = JournalService()
    private init() {}

    private var deviceId: String {
        if let stored = UserDefaults.standard.string(forKey: "hype_device_id") { return stored }
        let new = UUID().uuidString
        UserDefaults.standard.set(new, forKey: "hype_device_id")
        return new
    }

    private var todayString: String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    func getTodaysJournal() async throws -> DailyJournal? {
        let response: [DailyJournal] = try await SupabaseService.shared.client
            .from("daily_journal")
            .select()
            .eq("device_id", value: deviceId)
            .eq("date", value: todayString)
            .execute()
            .value
        return response.first
    }

    func saveJournal(entry: String, prompt: String?, feeling: String?) async throws {
        let words = entry.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        let record = DailyJournal(
            id: UUID(),
            deviceId: deviceId,
            date: todayString,
            entry: entry,
            prompt: prompt,
            feeling: feeling,
            wordCount: words,
            createdAt: Date(),
            updatedAt: Date()
        )
        try await SupabaseService.shared.client
            .from("daily_journal")
            .upsert(record)
            .execute()
    }
}
