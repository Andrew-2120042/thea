import SwiftUI
import Combine

struct RitualFlowView: View {
    @Binding var isPresented: Bool

    @StateObject private var affirmationVM = AffirmationViewModel()
    @StateObject private var recordingVM = RecordingViewModel()
    @StateObject private var hypeVM = HypeViewModel()
    @StateObject private var intentionsVM = IntentionsViewModel()
    @StateObject private var journalVM = JournalViewModel()
    @EnvironmentObject var storeKit: StoreKitService
    @EnvironmentObject var themeManager: ThemeManager

    @State private var page: Int = 1  // Start at ritual page
    @State private var pageOpacity: Double = 1.0
    @State private var bridgeOpacity: Double = 0.0
    @State private var isRecording = false
    @State private var selectedFeeling: String?

    private let lavenderBridge = LinearGradient(
        colors: [Color(red: 0.82, green: 0.84, blue: 0.97), Color(red: 0.72, green: 0.74, blue: 0.92)],
        startPoint: .top, endPoint: .bottom
    )

    var body: some View {
        ZStack {
            backgroundLayer
            currentPageView
                .opacity(pageOpacity)
            lavenderBridge
                .ignoresSafeArea()
                .opacity(bridgeOpacity)
                .allowsHitTesting(false)
        }
        .ignoresSafeArea()
        .onAppear {
            affirmationVM.loadAffirmation()
            Task { await intentionsVM.loadToday() }
        }
        .onChange(of: recordingVM.completionPercentage) { _, pct in
            guard page == 2, pct >= 1.0, !recordingVM.thresholdReached else { return }
            recordingVM.thresholdReached = true
            HapticManager.successCelebration()
        }
        .onChange(of: recordingVM.readyToAdvance) { _, ready in
            guard ready else { return }
            recordingVM.thresholdReached = true
            HapticManager.successCelebration()
        }
    }

    @ViewBuilder
    private var currentPageView: some View {
        switch page {
        case 1: ritualScreen
        case 2: affirmationScreen
        case 3: thanksScreen
        case 4: feelingScreen
        case 6: IntentionsInputView(
                    viewModel: intentionsVM,
                    feeling: selectedFeeling,
                    onContinue: { finishFlow() },
                    onSkip: { finishFlow() }
                )
        case 8: DayReviewView(
                    intentionsVM: intentionsVM,
                    onContinue: { go(9) },
                    onSkip: { finishFlow() }
                )
        case 9: JournalEntryView(
                    viewModel: journalVM,
                    feeling: selectedFeeling,
                    onComplete: { finishFlow() },
                    onSkip: { finishFlow() }
                )
        default: ritualScreen
        }
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        if page >= 3 && page <= 4 {
            lavenderBackground.ignoresSafeArea()
        } else {
            LinearGradient(
                colors: HypeColors.gradient(for: themeManager.activeTheme),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Page 1: Ritual Start
    private var ritualScreen: some View {
        VStack(spacing: 0) {
            flowNav(step: 0, onBack: { finishFlow() })

            VStack(spacing: 12) {
                StaggeredText(
                    text: "Let's start your\ndaily ritual",
                    font: .system(size: 36, weight: .regular, design: .serif),
                    color: .white,
                    lineSpacing: 8,
                    trigger: page == 1,
                    baseDelay: 0.2
                )

                StaggeredText(
                    text: "A few minutes to speak your truth\nand set your energy for the day.",
                    font: .system(size: 16),
                    color: .white.opacity(0.75),
                    lineSpacing: 8,
                    trigger: page == 1,
                    baseDelay: 0.8
                )
            }
            .padding(.horizontal, 40)
            .padding(.top, 44)

            Spacer()

            VStack(spacing: 14) {
                Button(action: {
                    HapticManager.impact(.medium)
                    go(2)
                }) {
                    Text("Yes, let's go")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 72)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
                }

                Button(action: { HapticManager.impact(.light); finishFlow() }) {
                    Text("Skip for now")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.75))
                        .underline()
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 60)
        }
    }

    // MARK: - Page 2: Affirmation + Recording
    private var affirmationScreen: some View {
        VStack(spacing: 0) {
            flowNav(step: 1, onBack: {
                if isRecording {
                    recordingVM.stopRecording()
                    isRecording = false
                } else {
                    go(1)
                }
            })

            Spacer()

            if affirmationVM.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            } else {
                let affirmationText = affirmationVM.currentAffirmation?.text ?? "I am worthy of all good things in this life."
                VStack(spacing: 20) {
                    if isRecording && recordingVM.speechService.isRecognizing {
                        HighlightedAffirmationText(
                            affirmation: affirmationText,
                            recognizedWords: recordingVM.speechService.recognizedWords
                        )
                        .padding(.horizontal, 36)
                        .transition(textTransition)
                    } else {
                        StaggeredText(
                            text: affirmationText,
                            font: .system(size: 30, weight: .regular, design: .serif),
                            color: .white,
                            lineSpacing: 8,
                            alignment: .center,
                            trigger: page == 2,
                            baseDelay: 0.15
                        )
                        .padding(.horizontal, 36)
                        .transition(textTransition)
                    }

                    if isRecording {
                        if recordingVM.speechService.isRecognizing {
                            let total = affirmationText.components(separatedBy: " ").filter { !$0.isEmpty }.count
                            let matched = HighlightedAffirmationText(
                                affirmation: affirmationText,
                                recognizedWords: recordingVM.speechService.recognizedWords
                            ).completionPercentage
                            let matchedCount = Int(matched * Double(total))
                            VStack(spacing: 8) {
                                if recordingVM.thresholdReached {
                                    Text("Perfect! 🎉")
                                        .font(.system(size: 20, weight: .semibold, design: .serif))
                                        .foregroundColor(.white)
                                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                                } else {
                                    HStack(spacing: 6) {
                                        Text("\(matchedCount) / \(total) words")
                                            .font(.system(size: 13))
                                            .foregroundColor(.white.opacity(0.55))
                                        Text("•")
                                            .foregroundColor(.white.opacity(0.3))
                                        Text("\(Int(matched * 100))%")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(recordingVM.speechService.isAboveThreshold
                                                  ? Color.green : Color.white.opacity(0.3))
                                            .frame(width: 7, height: 7)
                                            .animation(.easeInOut(duration: 0.15), value: recordingVM.speechService.isAboveThreshold)
                                        Text(recordingVM.speechService.isAboveThreshold ? "Loud enough ✓" : "Speak louder")
                                            .font(.system(size: 12))
                                            .foregroundColor(recordingVM.speechService.isAboveThreshold
                                                             ? .white.opacity(0.7) : .white.opacity(0.35))
                                            .animation(.easeInOut(duration: 0.15), value: recordingVM.speechService.isAboveThreshold)
                                    }
                                }
                            }
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: recordingVM.thresholdReached)
                            .transition(textTransition)
                        } else {
                            Text(recordingVM.feedback)
                                .font(.system(size: 16, weight: .regular, design: .serif))
                                .foregroundColor(recordingVM.feedbackColor)
                                .transition(textTransition)
                        }
                    } else {
                        StaggeredText(
                            text: "Read this out loud with confidence",
                            font: .system(size: 16),
                            color: .white.opacity(0.65),
                            lineSpacing: 4,
                            trigger: page == 2,
                            baseDelay: 0.55
                        )
                        .transition(textTransition)
                    }
                }
                .animation(.easeInOut(duration: 0.38), value: isRecording)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: recordingVM.speechService.recognizedWords)
            }

            Spacer()

            if isRecording {
                CircularVoiceDetector(
                    voiceLevel: recordingVM.voiceLevel,
                    threshold: affirmationVM.voiceThreshold
                )
                .transition(textTransition)
                .padding(.bottom, 16)
            }

            Spacer()

            actionButton
                .padding(.horizontal, 20)
                .padding(.bottom, 52)
        }
        .onDisappear {
            recordingVM.stopRecording()
            isRecording = false
        }
    }

    // MARK: - Page 3: Thanks
    private var thanksScreen: some View {
        ZStack {
            lavenderBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                darkFlowNav(filled: 2, onBack: { go(2) })

                VStack(spacing: 28) {
                    StaggeredText(
                        text: "Thanks for\nchecking in.",
                        font: .system(size: 40, weight: .regular, design: .serif),
                        color: darkText,
                        lineSpacing: 8,
                        trigger: page == 3,
                        baseDelay: 0.1
                    )
                    .padding(.horizontal, 32)
                    .padding(.top, 36)
                    .frame(maxWidth: .infinity, alignment: .center)

                    VStack(spacing: 10) {
                        Text("It appears you may be feeling")
                            .font(.system(size: 20, weight: .regular, design: .serif))
                            .foregroundColor(darkText)
                        Text(suggestedFeeling)
                            .font(.system(size: 20, weight: .regular, design: .serif))
                            .foregroundColor(darkText)
                            .padding(.horizontal, 20).padding(.vertical, 9)
                            .background(Color.white.opacity(0.75))
                            .clipShape(Capsule())
                        Text("Does that feel right?")
                            .font(.system(size: 20, weight: .regular, design: .serif))
                            .foregroundColor(darkText)
                    }
                    .multilineTextAlignment(.center)
                    .opacity(page == 3 ? 1 : 0)
                    .offset(y: page == 3 ? 0 : 14)
                    .animation(.easeOut(duration: 0.55).delay(0.45), value: page)
                }

                Spacer()

                VStack(spacing: 14) {
                    Button(action: { HapticManager.impact(.medium); go(4) }) {
                        Text("That feels right")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(darkText)
                            .frame(maxWidth: .infinity).frame(height: 72)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { HapticManager.impact(.light); go(2) }) {
                        Text("Repeat again")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(darkText)
                            .frame(maxWidth: .infinity).frame(height: 72)
                            .background(Color.white.opacity(0.45))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 60)
                .opacity(page == 3 ? 1 : 0)
                .offset(y: page == 3 ? 0 : 14)
                .animation(.easeOut(duration: 0.55).delay(0.65), value: page)
            }
        }
        .onAppear {
            let mode = affirmationVM.currentAffirmation?.mode.rawValue ?? "morning"
            hypeVM.loadHypeMessage(mode: mode)
            hypeVM.updateStreak(for: affirmationVM.currentAffirmation)
        }
    }

    // MARK: - Page 4: Feeling Selection
    private var feelingScreen: some View {
        ZStack {
            lavenderBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                darkFlowNav(filled: 4, onBack: { go(3) })

                StaggeredText(
                    text: "How do you feel now,\ncompared to before?",
                    font: .system(size: 36, weight: .regular, design: .serif),
                    color: darkText,
                    lineSpacing: 8,
                    trigger: page == 4,
                    baseDelay: 0.1
                )
                .padding(.horizontal, 32)
                .padding(.top, 36)
                .frame(maxWidth: .infinity, alignment: .center)

                Spacer()

                VStack(spacing: 14) {
                    ForEach(feelingOptions, id: \.self) { feeling in
                        Button(action: {
                            selectedFeeling = feeling
                            hypeVM.saveFeeling(feeling, for: affirmationVM.currentAffirmation)
                            HapticManager.selection()
                            navigateAfterFeeling()
                        }) {
                            Text(feeling)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(darkText)
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 24)
                                .frame(maxWidth: .infinity)
                                .background(Color.white.opacity(0.82))
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 60)
                .opacity(page == 4 ? 1 : 0)
                .offset(y: page == 4 ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.35), value: page)
            }
        }
    }

    // MARK: - Helper Views
    private var lavenderBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.82, green: 0.84, blue: 0.97),
                Color(red: 0.72, green: 0.74, blue: 0.92)
            ],
            startPoint: .top, endPoint: .bottom
        )
    }

    private var darkText: Color { HypeColors.textColor(for: themeManager.activeTheme) }

    private var suggestedFeeling: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let options = ["present", "calm", "grounded", "at ease", "peaceful"]
        return options[hour % options.count]
    }

    private let feelingOptions = [
        "I feel more in tune",
        "I feel a shift, but it's still settling",
        "I feel the same and that's okay",
        "Not sure, I need a bit more time",
    ]

    @ViewBuilder
    private func flowNav(step: Int, onBack: @escaping () -> Void) -> some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
            Spacer()
            ProgressDashes(total: 4, filled: step + 1, color: .white)
            Spacer()
            Button(action: finishFlow) {
                Image(systemName: "xmark")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }

    @ViewBuilder
    private func darkFlowNav(filled: Int, onBack: @escaping () -> Void) -> some View {
        let ink = Color(red: 0.18, green: 0.18, blue: 0.24)
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(ink)
                    .frame(width: 44, height: 44)
            }
            Spacer()
            ProgressDashes(total: 4, filled: filled)
            Spacer()
            Button(action: finishFlow) {
                Image(systemName: "xmark")
                    .font(.system(size: 16))
                    .foregroundColor(ink.opacity(0.7))
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }

    private var actionButton: some View {
        let isComplete = recordingVM.completionPercentage >= 1.0 || recordingVM.readyToAdvance

        return ZStack {
            if isRecording && !isComplete {
                Button(action: {}) {
                    Image(systemName: "waveform")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.black)
                        .frame(width: 80, height: 80)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
                }
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            } else if isComplete {
                Button(action: {
                    recordingVM.stopRecording()
                    isRecording = false
                    recordingVM.resetSession()
                    go(3)
                }) {
                    HStack(spacing: 10) {
                        Text("Continue")
                            .font(.system(size: 17, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 72)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
                }
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            } else {
                Button(action: { startInlineRecording() }) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 26, weight: .regular))
                        .foregroundColor(.black)
                        .frame(width: 80, height: 80)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
                }
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: isRecording)
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: isComplete)
    }

    private var textTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .offset(y: 14)),
            removal:   .opacity.combined(with: .offset(y: -14))
        )
    }

    // MARK: - Helper Methods

    private func navigateAfterFeeling() {
        if themeManager.activeTheme.isDaytime {
            Task { await intentionsVM.loadToday() }
            go(6)
        } else {
            Task { await intentionsVM.loadToday() }
            go(8)
        }
    }

    private func startInlineRecording() {
        withAnimation(.easeInOut(duration: 0.38)) { isRecording = true }
        let affirmationText = affirmationVM.currentAffirmation?.text ?? "I am worthy of all good things in this life."
        recordingVM.startRecording(threshold: affirmationVM.voiceThreshold, affirmation: affirmationText)
        HapticManager.impact(.medium)
    }

    private func finishFlow() {
        recordingVM.stopRecording()
        isRecording = false
        selectedFeeling = nil
        isPresented = false
    }

    private func go(_ p: Int) {
        let crossingBoundary = (page <= 2 && p >= 3) || (page >= 3 && p <= 2)

        if crossingBoundary {
            withAnimation(.easeIn(duration: 0.35)) { bridgeOpacity = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
                page = p
                withAnimation(.easeOut(duration: 0.55)) { bridgeOpacity = 0 }
            }
        } else if page >= 3 && p >= 3 {
            page = p
        } else {
            withAnimation(.easeIn(duration: 0.3)) { pageOpacity = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                page = p
                withAnimation(.easeOut(duration: 0.45)) { pageOpacity = 1 }
            }
        }
    }
}
