import SwiftUI

struct GetHypeView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @State private var showingMessage = false
    @State private var messageIndex = 0

    private let hypeMessages = [
        ("👑", "You are powerful beyond measure"),
        ("🔥", "Every day you choose yourself"),
        ("✨", "Your voice has the power to rewire your brain"),
        ("💜", "You deserve to feel this good every single day"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            onboardingHeader(step: 2, total: 8) {
                viewModel.prevStep()
            }

            Spacer()

            VStack(spacing: 40) {
                VStack(spacing: 12) {
                    Text("Get HYPED")
                        .font(.system(size: 36, weight: .bold, design: .serif))
                        .foregroundColor(.white)

                    Text("This is what you'll hear after every affirmation")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                // Animated hype message showcase
                ZStack {
                    ForEach(0..<hypeMessages.count, id: \.self) { index in
                        VStack(spacing: 16) {
                            Text(hypeMessages[index].0)
                                .font(.system(size: 60))

                            Text(hypeMessages[index].1)
                                .font(.system(size: 22, weight: .semibold, design: .serif))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .opacity(messageIndex == index ? 1 : 0)
                        .scaleEffect(messageIndex == index ? 1 : 0.9)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: messageIndex)
                    }
                }
                .frame(height: 180)
                .onAppear {
                    startCycling()
                }

                // Indicator dots
                HStack(spacing: 8) {
                    ForEach(0..<hypeMessages.count, id: \.self) { index in
                        Circle()
                            .fill(messageIndex == index ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
            }

            Spacer()

            GradientButton(title: "I want this! 🔥") {
                viewModel.nextStep()
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 52)
        }
    }

    private func startCycling() {
        Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
            withAnimation {
                messageIndex = (messageIndex + 1) % hypeMessages.count
            }
        }
    }
}
