import SwiftUI

struct HowItWorksView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel

    private let steps: [(icon: String, title: String, description: String)] = [
        ("🌅", "Morning & Night", "Two short check-ins a day. Morning to set your energy. Night to close with gratitude."),
        ("🎙️", "Speak Out Loud", "You don't just read — you speak. Your voice activates the affirmation."),
        ("🔥", "Build Your Streak", "Show up daily and watch your streak (and confidence) grow."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            onboardingHeader(step: 1, total: 8) {
                viewModel.prevStep()
            }

            Spacer()

            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("How HYPE works")
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("Three simple steps to transform your mindset")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 20) {
                    ForEach(steps, id: \.title) { step in
                        HowItWorksCard(icon: step.icon, title: step.title, description: step.description)
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer()

            GradientButton(title: "Sounds good!") {
                viewModel.nextStep()
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 52)
        }
    }
}

struct HowItWorksCard: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(icon)
                .font(.system(size: 36))
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
