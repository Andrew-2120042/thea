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
    // Brand accents — fixed, never change with theme
    static let primary   = Color(hex: "#8B5CF6")
    static let secondary = Color(hex: "#EC4899")
    static let accent    = Color(hex: "#F59E0B")
    static let streak    = Color(hex: "#F97316")

    // MARK: Theme-aware helpers

    /// The gradient stop colors for a given theme.
    /// Callers construct their own LinearGradient so they control start/end points.
    static func gradient(for theme: AppTheme) -> [Color] {
        switch theme {
        case .morning:
            return [Color(hex: "#FDB99B"), Color(hex: "#FCA15D"), Color(hex: "#F9845B")]
        case .afternoon:
            return [Color(hex: "#FFE5B4"), Color(hex: "#FFDAB9"), Color(hex: "#FFB6C1")]
        case .evening:
            return [Color(hex: "#E0BBE4"), Color(hex: "#C8A2C8"), Color(hex: "#B19CD9")]
        case .night:
            return [Color(hex: "#2C3E50"), Color(hex: "#3D5A80"), Color(hex: "#4A6FA5")]
        }
    }

    /// Primary text color for a given theme.
    /// Daytime themes use near-black (light backgrounds); evening/night use white.
    static func textColor(for theme: AppTheme) -> Color {
        theme.isDaytime
            ? Color(red: 0.08, green: 0.08, blue: 0.14)
            : .white
    }

    /// Card material — consistent across all themes.
    static func cardMaterial(for theme: AppTheme) -> Material {
        .ultraThinMaterial
    }
}

// MARK: - Settings Colors (shared by ProfileView + SettingsView)

struct HypeSettingsColors {
    static let accent = Color(red: 0.72, green: 0.34, blue: 0.26)  // warm terracotta
    static let bg     = Color(red: 0.97, green: 0.96, blue: 0.94)  // cream
    static let dark   = Color(red: 0.10, green: 0.10, blue: 0.14)  // near-black
    static let muted  = Color(red: 0.50, green: 0.50, blue: 0.54)  // mid gray
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
