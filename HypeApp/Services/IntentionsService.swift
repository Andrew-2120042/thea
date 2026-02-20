import Foundation

class IntentionsService {
    static let shared = IntentionsService()
    private init() {}

    private var deviceId: String {
        if let stored = UserDefaults.standard.string(forKey: "hype_device_id") {
            return stored
        }
        let new = UUID().uuidString
        UserDefaults.standard.set(new, forKey: "hype_device_id")
        return new
    }

    private var todayString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    func getTodaysIntentions() async throws -> DailyIntentions? {
        let response: [DailyIntentions] = try await SupabaseService.shared.client
            .from("daily_intentions")
            .select()
            .eq("device_id", value: deviceId)
            .eq("date", value: todayString)
            .execute()
            .value
        return response.first
    }

    func saveIntentions(intentions: [Intention], feeling: String?) async throws {
        let record = DailyIntentions(
            id: UUID(),
            deviceId: deviceId,
            date: todayString,
            intentions: intentions,
            feeling: feeling,
            createdAt: Date(),
            updatedAt: Date()
        )
        try await SupabaseService.shared.client
            .from("daily_intentions")
            .upsert(record)
            .execute()
    }

    func updateIntentions(_ updated: DailyIntentions) async throws {
        try await SupabaseService.shared.client
            .from("daily_intentions")
            .update(updated)
            .eq("id", value: updated.id.uuidString)
            .execute()
    }
}
