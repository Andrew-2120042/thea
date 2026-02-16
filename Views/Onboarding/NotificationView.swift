import SwiftUI

struct NotificationView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false

    var body: some View {
        VStack(spacing: 0) {
            onboardingHeader(step: 7, total: 8) {
                viewModel.prevStep()
            }

            Spacer()

            VStack(spacing: 40) {
                // Notification illustration
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 140, height: 140)

                    VStack(spacing: 8) {
                        Text("🔔")
                            .font(.system(size: 52))

                        Text("Daily reminders")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                VStack(spacing: 12) {
                    Text("Never miss a check-in")
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("We'll send you a gentle nudge at your chosen times so you never break your streak.")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                // Permission status
                if viewModel.notificationsGranted {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Notifications enabled!")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Color.green.opacity(0.15))
                    .clipShape(Capsule())
                }
            }

            Spacer()

            VStack(spacing: 12) {
                if !viewModel.notificationsGranted {
                    GradientButton(title: "Enable notifications 🔔") {
                        Task {
                            await viewModel.requestNotifications()
                        }
                    }
                }

                GradientButton(
                    title: viewModel.notificationsGranted ? "Let's go! 🚀" : "Maybe later",
                    action: {
                        viewModel.completeOnboarding()
                        withAnimation {
                            onboardingCompleted = true
                        }
                    },
                    gradient: viewModel.notificationsGranted
                        ? LinearGradient(colors: [HypeColors.primary, HypeColors.secondary], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [Color.white.opacity(0.2), Color.white.opacity(0.2)], startPoint: .leading, endPoint: .trailing)
                )
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 52)
        }
    }
}
