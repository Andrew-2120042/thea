import SwiftUI

// MARK: - AppTheme

enum AppTheme: String, CaseIterable {
    case morning, afternoon, evening, night

    var greeting: String {
        switch self {
        case .morning:   return "Good morning"
        case .afternoon: return "Good afternoon"
        case .evening:   return "Good evening"
        case .night:     return "Good night"
        }
    }

    /// True for morning and afternoon (daytime)
    var isDaytime: Bool {
        self == .morning || self == .afternoon
    }

    /// The opposite theme used for the manual day/night toggle
    var opposite: AppTheme {
        isDaytime ? .night : .morning
    }

    var affirmationMode: Affirmation.AffirmationMode {
        isDaytime ? .morning : .night
    }
}

// MARK: - ThemeManager

final class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme

    // MARK: Manual override — persisted across launches

    var isManualOverride: Bool {
        get { UserDefaults.standard.bool(forKey: "themeManualOverride") }
        set {
            UserDefaults.standard.set(newValue, forKey: "themeManualOverride")
            objectWillChange.send()
        }
    }

    var manualTheme: AppTheme {
        get {
            let raw = UserDefaults.standard.string(forKey: "themeManualValue") ?? ""
            return AppTheme(rawValue: raw) ?? .night
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "themeManualValue")
            objectWillChange.send()
        }
    }

    /// The effective theme — manual if override is on, auto-detected otherwise
    var activeTheme: AppTheme {
        isManualOverride ? manualTheme : currentTheme
    }

    // MARK: Init

    init() {
        currentTheme = ThemeManager.themeForCurrentHour()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshTheme),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    // MARK: Toggle

    /// Flips manual override. When enabling, sets the manual theme to the opposite
    /// of the current auto theme (sun/moon toggle behaviour).
    func toggleManualOverride() {
        if isManualOverride {
            isManualOverride = false
        } else {
            manualTheme = currentTheme.opposite
            isManualOverride = true
        }
    }

    // MARK: Internal

    @objc private func refreshTheme() {
        currentTheme = ThemeManager.themeForCurrentHour()
    }

    /// Maps the current system hour to an AppTheme. Shared as a static so ViewModels
    /// can call it without holding a reference to the environment object.
    static func themeForCurrentHour() -> AppTheme {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<21: return .evening
        default:      return .night
        }
    }
}
