import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo area
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 100, height: 100)
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 130, height: 130)
                    Text("✨")
                        .font(.system(size: 44))
                }

                Text("HYPE")
                    .font(.system(size: 52, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                    .tracking(8)

                Text("Voice Affirmations")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(.white.opacity(0.8))
                    .tracking(2)
            }

            Spacer()
            Spacer()

            // Description
            VStack(spacing: 12) {
                Text("Speak your worth into existence.")
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Daily affirmations you actually say out loud — because hearing your own voice changes everything.")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 8)
            }
            .padding(.horizontal, 40)

            Spacer()

            // CTA
            VStack(spacing: 12) {
                GradientButton(title: "Let's get started") {
                    viewModel.nextStep()
                }

                Text("Already have an account? Sign in")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 52)
        }
    }
}
