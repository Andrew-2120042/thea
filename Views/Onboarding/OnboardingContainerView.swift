import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        ZStack {
            // Background
            TimeBasedGradientBackground()

            // Steps
            Group {
                switch viewModel.currentStep {
                case 0: WelcomeView()
                case 1: HowItWorksView()
                case 2: GetHypeView()
                case 3: NameInputView()
                case 4: FrequencyView()
                case 5: CategoryView()
                case 6: VoiceSetupView()
                case 7: NotificationView()
                default: WelcomeView()
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .id(viewModel.currentStep)
            .animation(.easeInOut(duration: 0.35), value: viewModel.currentStep)
        }
        .environmentObject(viewModel)
        .ignoresSafeArea()
    }
}
