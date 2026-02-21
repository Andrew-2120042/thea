import SwiftUI

struct AffirmationView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = AffirmationViewModel()
    @State private var showRecording = false
    @State private var showPaywall = false
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 30

    var body: some View {
        ZStack {
            GradientVideoBackground(gradient: viewModel.getCurrentGradient())

            VStack(spacing: 0) {
                // Navigation bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }

                    Spacer()

                    ProgressDots(total: 4, current: 0)

                    Spacer()

                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                Spacer()

                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                } else {
                    VStack(spacing: 28) {
                        // Mode badge
                        Text(isEvening ? "🌙 NIGHT AFFIRMATION" : "🌅 MORNING AFFIRMATION")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                            .tracking(2)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Capsule())

                        // Affirmation text
                        Text(viewModel.currentAffirmation?.text ?? "I am worthy of all good things in this life.")
                            .font(.system(size: 28, weight: .semibold, design: .serif))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                            .padding(.horizontal, 36)
                            .opacity(textOpacity)
                            .offset(y: textOffset)

                        Text("Read this out loud with confidence")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.65))
                            .opacity(textOpacity)
                    }
                }

                Spacer()
                Spacer()

                // Mic button + instructions
                VStack(spacing: 20) {
                    GlassMicButton(action: {
                        showRecording = true
                        HapticManager.impact(.heavy)
                    }, size: 110)

                    VStack(spacing: 4) {
                        Text("TAP TO SPEAK")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(3)

                        Text("Hold the affirmation in your mind as you speak")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    // Skip button for testing
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Skip")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .underline()
                    }
                    .padding(.top, 12)
                }

                Spacer()
                    .frame(height: 60)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            viewModel.loadAffirmation()
            animateText()
        }
        .onChange(of: viewModel.showPaywall) { show in
            if show {
                dismiss()
                showPaywall = true
            }
        }
        .fullScreenCover(isPresented: $showRecording) {
            RecordingView(
                affirmation: viewModel.currentAffirmation,
                threshold: viewModel.voiceThreshold
            )
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private var isEvening: Bool {
        Calendar.current.component(.hour, from: Date()) >= 17
    }

    private func animateText() {
        withAnimation(.easeOut(duration: 0.7).delay(0.3)) {
            textOpacity = 1
            textOffset = 0
        }
    }
}
