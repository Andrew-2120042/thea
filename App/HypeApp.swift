import SwiftUI

@main
struct HypeApp: App {
    @StateObject private var storeKit = StoreKitService()
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false

    var body: some Scene {
        WindowGroup {
            if onboardingCompleted {
                MainContainerView()
                    .environmentObject(storeKit)
            } else {
                OnboardingContainerView()
                    .environmentObject(storeKit)
            }
        }
    }
}
