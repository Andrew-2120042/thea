import SwiftUI

struct RecordingView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = RecordingViewModel()
    @State private var showHype = false
    @State private var progressSeconds: Double = 0

    let affirmation: Affirmation?
    let threshold: Double

    var body: some View {
        ZStack {
            GradientVideoBackground(gradient: currentGradient)

            VStack(spacing: 0) {
                // Nav bar
                HStack {
                    Button(action: {
                        viewModel.stopRecording()
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }

                    Spacer()

                    ProgressDots(total: 4, current: 1)

                    Spacer()

                    Button(action: {
                        viewModel.stopRecording()
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                VStack(spacing: 8) {
                    Text("I'm listening")
                        .font(.system(size: 28, weight: .semibold, design: .serif))
                        .foregroundColor(.white)

                    Text("Speak for at least 3 seconds above the threshold")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 24)

                Spacer()

                // Circular voice detector - the hero component
                CircularVoiceDetector(
                    voiceLevel: viewModel.voiceLevel,
                    threshold: threshold
                )

                Spacer()

                // Affirmation reminder
                if let text = affirmation?.text {
                    Text("\"\(text)\"")
                        .font(.system(size: 15, weight: .medium, design: .serif))
                        .foregroundColor(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .italic()
                }

                Spacer()

                // Dynamic feedback
                Text(viewModel.feedback)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(viewModel.feedbackColor)
                    .padding(.bottom, 100)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.feedback)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            viewModel.startRecording(threshold: threshold, affirmation: affirmation?.text ?? "")
        }
        .onDisappear {
            viewModel.stopRecording()
        }
        .onChange(of: viewModel.speechService.completionPercentage) { pct in
            guard pct >= 0.90, !viewModel.thresholdReached else { return }
            viewModel.thresholdReached = true
            HapticManager.successCelebration()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                viewModel.stopRecording()
                showHype = true
            }
        }
        .onChange(of: viewModel.readyToAdvance) { ready in
            guard ready else { return }
            viewModel.resetSession()
            showHype = true
        }
        .fullScreenCover(isPresented: $showHype) {
            HypeView(affirmation: affirmation)
        }
    }

    private var currentGradient: LinearGradient {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return HypeColors.morningGradient
        case 12..<17: return HypeColors.afternoonGradient
        case 17..<21: return HypeColors.eveningGradient
        default: return HypeColors.nightGradient
        }
    }
}
