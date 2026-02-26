import SwiftUI

struct HypeView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var viewModel = HypeViewModel()
    @State private var selectedFeeling: String?
    @State private var showConfetti = true
    @State private var hypeTextOpacity: Double = 0
    @State private var hypeTextScale: CGFloat = 0.7
    @State private var streakOpacity: Double = 0

    let affirmation: Affirmation?

    var body: some View {
        ZStack {
            GradientVideoBackground(gradient: LinearGradient(
                colors: HypeColors.gradient(for: themeManager.activeTheme),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))

            // Confetti
            if showConfetti {
                ConfettiView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                            showConfetti = false
                        }
                    }
            }

            VStack(spacing: 0) {
                // Nav
                HStack {
                    Spacer()
                    ProgressDots(total: 4, current: 2)
                    Spacer()

                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                Spacer()

                // Hype message
                VStack(spacing: 20) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(viewModel.hypeMessage?.text ?? "YES QUEEN! 🔥")
                            .font(.system(size: 30, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 36)
                            .opacity(hypeTextOpacity)
                            .scaleEffect(hypeTextScale)
                    }

                    // Streak badge
                    if viewModel.currentStreak > 0 {
                        HStack(spacing: 8) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(HypeColors.streak)
                            Text("\(viewModel.currentStreak) DAY STREAK")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                            Image(systemName: "flame.fill")
                                .foregroundColor(HypeColors.streak)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .opacity(streakOpacity)
                    }
                }

                Spacer()

                // Feeling check-in
                VStack(spacing: 16) {
                    Text("How do you feel now,\ncompared to before?")
                        .font(.system(size: 22, weight: .semibold, design: .serif))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    VStack(spacing: 10) {
                        ForEach(feelings, id: \.self) { feeling in
                            FeelingButton(
                                text: feeling,
                                isSelected: selectedFeeling == feeling,
                                action: {
                                    withAnimation(.spring(response: 0.25)) {
                                        selectedFeeling = feeling
                                    }
                                    HapticManager.selection()
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, 32)

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    GradientButton(title: "That feels right ✨") {
                        if let feeling = selectedFeeling {
                            viewModel.saveFeeling(feeling, for: affirmation)
                        }
                        HapticManager.impact(.medium)
                        dismiss()
                    }

                    Button(action: {
                        HapticManager.impact(.light)
                        dismiss()
                    }) {
                        Text("Repeat again")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.75))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            let mode = affirmation?.mode.rawValue ?? "morning"
            viewModel.loadHypeMessage(mode: mode)
            viewModel.updateStreak(for: affirmation)
            animateEntrance()
        }
    }

    private let feelings = [
        "I feel more in tune 🌟",
        "I feel a shift, but it's still settling",
        "I feel the same and that's okay",
        "Not sure, I need a bit more time",
    ]


    private func animateEntrance() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
            hypeTextOpacity = 1
            hypeTextScale = 1.0
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
            streakOpacity = 1
        }
    }
}

// MARK: - Feeling Button
struct FeelingButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    isSelected
                        ? HypeColors.primary.opacity(0.6)
                        : Color.white.opacity(0.1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            isSelected ? HypeColors.primary : Color.white.opacity(0.2),
                            lineWidth: 1.5
                        )
                )
        }
        .buttonStyle(GlassButtonStyle())
    }
}
