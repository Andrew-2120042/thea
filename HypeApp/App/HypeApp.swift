import SwiftUI

@main
struct HypeApp: App {
    @StateObject private var storeKit = StoreKitService()
    @StateObject private var themeManager = ThemeManager()
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false

    var body: some Scene {
        WindowGroup {
            if onboardingCompleted {
                MainContainerView()
                    .environmentObject(storeKit)
                    .environmentObject(themeManager)
            } else {
                OnboardingContainerView()
                    .environmentObject(storeKit)
                    .environmentObject(themeManager)
            }
        }
    }
}
