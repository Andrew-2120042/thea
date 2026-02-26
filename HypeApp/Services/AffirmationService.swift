import Foundation

class AffirmationService {
    static let shared = AffirmationService()

    // MARK: - Fallback affirmations when Supabase is unavailable
    let fallbackAffirmations: [Affirmation] = [
        Affirmation(id: UUID(), text: "I am worthy of love, success, and all good things.", mode: .morning, category: "confidence", active: true, orderIndex: 1),
        Affirmation(id: UUID(), text: "I trust myself to handle whatever comes my way.", mode: .morning, category: "confidence", active: true, orderIndex: 2),
        Affirmation(id: UUID(), text: "My potential is limitless and I am just getting started.", mode: .morning, category: "confidence", active: true, orderIndex: 3),
        Affirmation(id: UUID(), text: "I am the main character of my own beautiful story.", mode: .morning, category: "self-care", active: true, orderIndex: 4),
        Affirmation(id: UUID(), text: "I give myself permission to rest and recharge.", mode: .morning, category: "self-care", active: true, orderIndex: 5),
        Affirmation(id: UUID(), text: "My boundaries are an act of self-love and respect.", mode: .morning, category: "boundaries", active: true, orderIndex: 6),
        Affirmation(id: UUID(), text: "I attract abundance in every area of my life.", mode: .morning, category: "abundance", active: true, orderIndex: 7),
        Affirmation(id: UUID(), text: "Today I choose joy, confidence, and peace.", mode: .night, category: "gratitude", active: true, orderIndex: 1),
        Affirmation(id: UUID(), text: "I release the day with gratitude and step into rest.", mode: .night, category: "healing", active: true, orderIndex: 2),
        Affirmation(id: UUID(), text: "I did my best today and that is enough.", mode: .night, category: "self-care", active: true, orderIndex: 3),
        Affirmation(id: UUID(), text: "I am proud of every small step I took today.", mode: .night, category: "confidence", active: true, orderIndex: 4),
        Affirmation(id: UUID(), text: "Tomorrow I wake up even more powerful.", mode: .night, category: "confidence", active: true, orderIndex: 5),
    ]

    private let fallbackHypeMessages: [HypeMessage] = [
        HypeMessage(id: UUID(), text: "YES QUEEN! That's the energy! 🔥", mode: "morning", active: true),
        HypeMessage(id: UUID(), text: "You just unlocked a new level of yourself! ✨", mode: "morning", active: true),
        HypeMessage(id: UUID(), text: "She believed she could, so she did. That's YOU. 💜", mode: "morning", active: true),
        HypeMessage(id: UUID(), text: "The universe just took note of your energy! 🌟", mode: "morning", active: true),
        HypeMessage(id: UUID(), text: "You are THAT girl and don't you forget it! 👑", mode: "morning", active: true),
        HypeMessage(id: UUID(), text: "Rest well queen — tomorrow you conquer again. 🌙", mode: "night", active: true),
        HypeMessage(id: UUID(), text: "You showed up for yourself today. That matters. 💫", mode: "night", active: true),
        HypeMessage(id: UUID(), text: "Sweet dreams, powerful soul. 🌟", mode: "night", active: true),
    ]

    // MARK: - Get Today's Affirmation
    func getTodaysAffirmation(
        mode: Affirmation.AffirmationMode,
        categories: [String],
        deviceId: String
    ) async throws -> Affirmation? {
        do {
            // Check if already completed today
            let today = Calendar.current.startOfDay(for: Date())
            let activity: [UserActivity] = try await SupabaseService.shared.client
                .from("user_activity")
                .select()
                .eq("device_id", value: deviceId)
                .eq("mode", value: mode.rawValue)
                .gte("created_at", value: ISO8601DateFormatter().string(from: today))
                .execute()
                .value

            if !activity.isEmpty {
                return nil // Already completed today
            }

            // Fetch affirmations from Supabase
            let affirmations: [Affirmation] = try await SupabaseService.shared.client
                .from("affirmations")
                .select()
                .eq("mode", value: mode.rawValue)
                .eq("active", value: true)
                .in("category", values: categories.isEmpty ? ["confidence"] : categories)
                .execute()
                .value

            return affirmations.randomElement() ?? getFallbackAffirmation(mode: mode, categories: categories)
        } catch {
            // Fall back to local affirmations if Supabase unavailable
            return getFallbackAffirmation(mode: mode, categories: categories)
        }
    }

    func getFallbackAffirmation(mode: Affirmation.AffirmationMode, categories: [String]) -> Affirmation? {
        let filtered = fallbackAffirmations.filter { $0.mode == mode }
        return filtered.randomElement()
    }

    // MARK: - Get Random Hype Message
    func getRandomHypeMessage(mode: String) async throws -> HypeMessage? {
        do {
            let messages: [HypeMessage] = try await SupabaseService.shared.client
                .from("hype_messages")
                .select()
                .eq("mode", value: mode)
                .eq("active", value: true)
                .execute()
                .value

            return messages.randomElement() ?? fallbackHypeMessages.filter { $0.mode == mode }.randomElement()
        } catch {
            return fallbackHypeMessages.filter { $0.mode == mode }.randomElement()
        }
    }

    // MARK: - Save Activity
    func saveActivity(_ activity: UserActivity) async throws {
        try await SupabaseService.shared.client
            .from("user_activity")
            .insert(activity)
            .execute()
    }

    // MARK: - Get Categories
    func getCategories() async throws -> [AffirmationCategory] {
        do {
            let categories: [AffirmationCategory] = try await SupabaseService.shared.client
                .from("categories")
                .select()
                .eq("active", value: true)
                .order("order_index")
                .execute()
                .value
            return categories
        } catch {
            return AffirmationCategory.defaults
        }
    }

    // MARK: - Get Calendar Activities
    func getActivities(deviceId: String, from startDate: Date, to endDate: Date) async throws -> [UserActivity] {
        do {
            let activities: [UserActivity] = try await SupabaseService.shared.client
                .from("user_activity")
                .select()
                .eq("device_id", value: deviceId)
                .gte("created_at", value: ISO8601DateFormatter().string(from: startDate))
                .lte("created_at", value: ISO8601DateFormatter().string(from: endDate))
                .execute()
                .value
            return activities
        } catch {
            return []
        }
    }
}
