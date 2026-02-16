import SwiftUI

struct VoiceSetupView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @StateObject private var voiceService = VoiceService()
    @State private var isCalibrating = false
    @State private var calibrationDone = false
    @State private var currentVoiceLevel: Double = 0
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        VStack(spacing: 0) {
            onboardingHeader(step: 6, total: 8) {
                if isCalibrating { voiceService.stopMonitoring() }
                viewModel.prevStep()
            }

            Spacer()

            VStack(spacing: 32) {
                VStack(spacing: 12) {
                    Text("Set your voice level")
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("Tap the mic and say an affirmation. We'll calibrate to your normal speaking voice.")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Voice detector
                CircularVoiceDetector(
                    voiceLevel: currentVoiceLevel,
                    threshold: viewModel.voiceThreshold
                )

                if calibrationDone {
                    VStack(spacing: 8) {
                        Text("✅ Voice level set!")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Threshold: \(Int(viewModel.voiceThreshold))%")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.75))
                    }
                    .transition(.opacity.combined(with: .scale))
                } else {
                    // Calibrate button
                    Button(action: toggleCalibration) {
                        HStack(spacing: 12) {
                            Image(systemName: isCalibrating ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.system(size: 22))
                            Text(isCalibrating ? "Stop listening" : "Tap to calibrate")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(
                            isCalibrating
                                ? Color.red.opacity(0.3)
                                : Color.white.opacity(0.15)
                        )
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
                    }
                }

                // Threshold slider
                VStack(spacing: 8) {
                    Text("Or set manually")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))

                    HStack {
                        Text("Quiet")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                        Slider(value: $viewModel.voiceThreshold, in: 30...90, step: 5)
                            .tint(HypeColors.primary)
                        Text("Loud")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 32)
                }
            }

            Spacer()

            GradientButton(title: "Sounds perfect") {
                voiceService.stopMonitoring()
                viewModel.nextStep()
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 52)
        }
        .onAppear {
            setupVoiceMonitoring()
            Task { await viewModel.requestMicrophone() }
        }
        .onDisappear {
            voiceService.stopMonitoring()
        }
    }

    private func toggleCalibration() {
        if isCalibrating {
            voiceService.stopMonitoring()
            isCalibrating = false
        } else {
            voiceService.startMonitoring()
            isCalibrating = true
        }
        HapticManager.impact(.medium)
    }

    private func setupVoiceMonitoring() {
        voiceService.$voiceLevel
            .receive(on: DispatchQueue.main)
            .sink { level in
                currentVoiceLevel = level
                // Auto-calibrate: set threshold to 80% of peak
                if level > 10 && isCalibrating {
                    viewModel.voiceThreshold = min(85, level * 0.8)
                }
            }
            .store(in: &cancellables)

        voiceService.onThresholdReached = {
            isCalibrating = false
            calibrationDone = true
            HapticManager.successCelebration()
        }
    }
}

import Combine
