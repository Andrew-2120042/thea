import SwiftUI

struct FrequencyView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel

    private let options = [
        (value: 7, label: "Once a day", description: "Morning only"),
        (value: 14, label: "Twice a day", description: "Morning + Night (Recommended)"),
        (value: 21, label: "Morning + 2x Night", description: "For maximum impact"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            onboardingHeader(step: 4, total: 8) {
                viewModel.prevStep()
            }

            Spacer()

            VStack(spacing: 32) {
                VStack(spacing: 12) {
                    Text("How often do you want to show up?")
                        .font(.system(size: 30, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                    Text("You can change this anytime in settings")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.7))
                }

                // Schedule toggles
                VStack(spacing: 16) {
                    ToggleCard(
                        icon: "🌅",
                        title: "Morning",
                        subtitle: "Start the day empowered",
                        isOn: $viewModel.morningEnabled,
                        time: $viewModel.morningTime
                    )

                    ToggleCard(
                        icon: "🌙",
                        title: "Night",
                        subtitle: "End the day with gratitude",
                        isOn: $viewModel.nightEnabled,
                        time: $viewModel.nightTime
                    )
                }
                .padding(.horizontal, 24)
            }

            Spacer()

            GradientButton(title: "Set my schedule") {
                viewModel.nextStep()
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 52)
        }
    }
}

// MARK: - Toggle Card
struct ToggleCard: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    @Binding var time: Date
    var textColor: Color = .white

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(icon)
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(textColor)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(textColor.opacity(0.55))
                }

                Spacer()

                Toggle("", isOn: $isOn)
                    .tint(HypeColors.primary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            if isOn {
                Divider()
                    .background(textColor.opacity(0.15))
                    .padding(.horizontal, 20)

                HStack {
                    Text("Reminder time")
                        .font(.system(size: 14))
                        .foregroundColor(textColor.opacity(0.6))

                    Spacer()

                    DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .colorInvert()
                        .colorMultiply(HypeColors.primary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.25), value: isOn)
    }
}
