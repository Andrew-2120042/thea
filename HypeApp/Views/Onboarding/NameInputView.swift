import SwiftUI

struct NameInputView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @FocusState private var nameFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            onboardingHeader(step: 3, total: 8) {
                viewModel.prevStep()
            }

            Spacer()

            VStack(spacing: 32) {
                VStack(spacing: 12) {
                    Text("What's your name?")
                        .font(.system(size: 34, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("We'll personalise your experience")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.75))
                }

                // Name input with glass effect
                VStack(alignment: .leading, spacing: 8) {
                    TextField("", text: $viewModel.userName)
                        .placeholder(when: viewModel.userName.isEmpty) {
                            Text("Your name...")
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .font(.system(size: 24, weight: .semibold, design: .serif))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .focused($nameFieldFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            if !viewModel.userName.isEmpty {
                                viewModel.nextStep()
                            }
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 24)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                        )

                    if !viewModel.userName.isEmpty {
                        Text("Hi \(viewModel.userName)! 👋")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 8)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(.horizontal, 32)
            }

            Spacer()

            GradientButton(
                title: "Continue",
                action: { viewModel.nextStep() },
                disabled: viewModel.userName.trimmingCharacters(in: .whitespaces).isEmpty
            )
            .padding(.horizontal, 32)
            .padding(.bottom, 52)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                nameFieldFocused = true
            }
        }
    }
}

// MARK: - Placeholder Extension
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: .center) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
