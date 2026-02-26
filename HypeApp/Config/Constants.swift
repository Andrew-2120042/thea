import SwiftUI

struct Constants {
    // MARK: - Supabase
    // Replace with your actual Supabase project URL and anon key
    static let supabaseURL = "https://apavydxenvhitrjezmzh.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFwYXZ5ZHhlbnZoaXRyamV6bXpoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA5OTQyMDUsImV4cCI6MjA4NjU3MDIwNX0.p9ECdhOQgOuMgs9C_UuhsmvWd2R-H3-z6k2NRS1duJ8"

    // MARK: - StoreKit Product IDs
    // Replace with your App Store Connect product IDs
    static let monthlySubscriptionID = "com.yourcompany.HypeApp.monthly"
    static let yearlySubscriptionID = "com.yourcompany.HypeApp.yearly"

    // MARK: - Free Tier
    #if DEBUG
    static let freeAffirmationLimit = 9999
    #else
    static let freeAffirmationLimit = 7
    #endif

    // MARK: - App Storage Keys
    static let userSettingsKey = "userSettings"
    static let onboardingCompletedKey = "onboardingCompleted"
}

// MARK: - Hype Colors
struct HypeColors {
    static let morningGradient = LinearGradient(
        colors: [Color(hex: "#B8C8D8"), Color(hex: "#D4A96A"), Color(hex: "#8090A8")],
        startPoint: .top,
        endPoint: .bottom
    )

    static let afternoonGradient = LinearGradient(
        colors: [Color(hex: "#60A5FA"), Color(hex: "#93C5FD"), Color(hex: "#3B82F6")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let eveningGradient = LinearGradient(
        colors: [Color(hex: "#F59E0B"), Color(hex: "#EC4899"), Color(hex: "#8B5CF6")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let nightGradient = LinearGradient(
        colors: [Color(hex: "#C4B5E8"), Color(hex: "#A8C4E8"), Color(hex: "#E8D5C4")],
        startPoint: .top,
        endPoint: .bottom
    )

    static let primary = Color(hex: "#8B5CF6")
    static let secondary = Color(hex: "#EC4899")
    static let accent = Color(hex: "#F59E0B")
    static let streak = Color(hex: "#F97316")
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 200, 200, 200)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
