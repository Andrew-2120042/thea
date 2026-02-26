import SwiftUI
import Combine

// Pages: 0=home  1=ritual  2=affirmation+recording  3=thanks  4=feeling  5=calendar
struct HomeView: View {
    var goToTrends: () -> Void = {}

    @StateObject private var homeVM        = HomeViewModel()
    @StateObject private var affirmationVM = AffirmationViewModel()
    @StateObject private var recordingVM   = RecordingViewModel()
    @StateObject private var hypeVM        = HypeViewModel()
    @StateObject private var intentionsVM  = IntentionsViewModel()
    @StateObject private var journalVM     = JournalViewModel()
    @EnvironmentObject var storeKit: StoreKitService

    @State private var page: Int = 0
    @State private var pageOpacity: Double = 1.0
    @State private var bridgeOpacity: Double = 0.0
    @State private var isRecording = false          // inline on page 2
    @State private var showSettings  = false
    @State private var showPaywall   = false
    @State private var showInsights  = false
    @State private var selectedFeeling: String?

    // Lavender used as the bridge colour between gradient and lavender pages
    private let lavenderBridge = LinearGradient(
        colors: [Color(red: 0.82, green: 0.84, blue: 0.97), Color(red: 0.72, green: 0.74, blue: 0.92)],
        startPoint: .top, endPoint: .bottom
    )

    var body: some View {
        ZStack {
            backgroundLayer
            currentPageView
                .opacity(pageOpacity)
            // Lavender bridge overlay — only visible during gradient↔lavender transitions
            lavenderBridge
                .ignoresSafeArea()
                .opacity(bridgeOpacity)
                .allowsHitTesting(false)
        }
        .ignoresSafeArea()
        .onAppear {
            homeVM.loadUserData()
            Task { await intentionsVM.loadToday() }
        }
        // Haptic celebration when all words matched — navigation is via the Continue button
        .onChange(of: recordingVM.completionPercentage) { _, pct in
            guard page == 2, pct >= 1.0, !recordingVM.thresholdReached else { return }
            recordingVM.thresholdReached = true
            HapticManager.successCelebration()
        }
        // Voice-level fallback: mark ready so Continue button enables
        .onChange(of: recordingVM.readyToAdvance) { _, ready in
            guard ready else { return }
            recordingVM.thresholdReached = true
            HapticManager.successCelebration()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView().environmentObject(storeKit)
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView().environmentObject(storeKit)
        }
        .fullScreenCover(isPresented: $showInsights) {
            InsightsContainerView()
        }
    }

    @ViewBuilder
    private var currentPageView: some View {
        switch page {
        case 0: homeScreen
        case 1: ritualScreen
        case 2: affirmationScreen
        case 3: thanksScreen
        case 4: feelingScreen
        case 5: calendarScreen
        case 6: IntentionsInputView(
                    viewModel: intentionsVM,
                    feeling: selectedFeeling,
                    onContinue: { finishFlow() },
                    onSkip: { go(5) }
                )
        case 7: TodaysIntentionsView(
                    viewModel: intentionsVM,
                    todaysAffirmation: affirmationVM.currentAffirmation?.text,
                    onDone: { finishFlow() }
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
        default: homeScreen
        }
    }

    // MARK: - Background
    // Fades out when moving to non-gradient pages so lavender/cream don't flash
    @ViewBuilder
    private var backgroundLayer: some View {
        Group {
            if let uiImage = UIImage(named: "Background") {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.98, green: 0.85, blue: 0.75),
                        Color(red: 0.95, green: 0.65, blue: 0.55),
                        Color(red: 0.3,  green: 0.35, blue: 0.5)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .ignoresSafeArea()
        .opacity(page <= 2 ? 1.0 : 0.0) // pages 3+ have their own backgrounds
    }

    // MARK: - Page 0: Home
    private var homeScreen: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Text("The Sage")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(.white)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                Spacer()
                Button(action: { showSettings = true }) {
                    Image(systemName: "person")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)

            // Greeting — one word per line, large stacked serif
            StaggeredText(
                text: greetingStacked,
                font: .system(size: 76, weight: .regular, design: .serif),
                color: .white,
                lineSpacing: -10,
                trigger: page == 0,
                baseDelay: 0.15
            )
            .padding(.top, 32)

            Spacer()

            // Intentions preview — morning shows focus, night shows completion
            if !intentionsVM.intentions.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text(isMorning ? "TODAY'S FOCUS" : "TODAY'S PROGRESS")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(1.5)

                    ForEach(intentionsVM.intentions.prefix(3)) { item in
                        HStack(spacing: 10) {
                            Image(systemName: item.completed ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(item.completed ? 1.0 : 0.55))
                            Text(item.text)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(item.completed ? 0.5 : 0.88))
                                .strikethrough(item.completed)
                                .lineLimit(1)
                        }
                    }

                    if !isMorning {
                        let done = intentionsVM.intentions.filter { $0.completed }.count
                        Text("\(done) of \(intentionsVM.intentions.count) complete")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 20)
            }

            Button(action: startFlow) {
                Text(homeVM.isAllCompletedToday ? "Completed today ✓" : "Check in")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 72)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            .disabled(homeVM.isAllCompletedToday)

            HStack {
                Spacer()
                Button(action: { showInsights = true }) {
                    Text("Trends")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .underline()
                }
                Spacer()
            }
            .padding(.bottom, 36)

            #if DEBUG
            VStack(spacing: 6) {
                Text("DEBUG — \(isMorningOverride == 1 ? "☀️ MORNING" : isMorningOverride == 2 ? "🌙 EVENING" : "⏱ AUTO (\(isMorning ? "morning" : "evening"))")")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(1)
                HStack(spacing: 10) {
                    Button("☀️ Morning") {
                        isMorningOverride = 1
                        UserDefaults.standard.set(1, forKey: "debug_time_mode")
                    }
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(isMorningOverride == 1 ? Color.white.opacity(0.25) : Color.clear)
                    .clipShape(Capsule())

                    Button("🌙 Evening") {
                        isMorningOverride = 2
                        UserDefaults.standard.set(2, forKey: "debug_time_mode")
                    }
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(isMorningOverride == 2 ? Color.white.opacity(0.25) : Color.clear)
                    .clipShape(Capsule())

                    Button("Auto") {
                        isMorningOverride = 0
                        UserDefaults.standard.set(0, forKey: "debug_time_mode")
                    }
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(isMorningOverride == 0 ? Color.white.opacity(0.25) : Color.clear)
                    .clipShape(Capsule())
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.6))

                HStack(spacing: 10) {
                    Button("✓ Intentions") {
                        go(7)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Capsule())

                    Button("📝 Journal") {
                        go(9)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Capsule())
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            }
            .padding(.bottom, 16)
            #endif
        }
    }

    // MARK: - Page 1: Ritual
    private var ritualScreen: some View {
        VStack(spacing: 0) {
            flowNav(step: 0, onBack: { go(0) })

            // Text pinned near top, no emoji
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
                    affirmationVM.loadAffirmation()
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

                Button(action: { HapticManager.impact(.light); go(5) }) {
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

    // MARK: - Page 2: Affirmation + inline recording
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

            // Affirmation text — word-by-word highlight when recording, staggered when idle
            if affirmationVM.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            } else {
                let affirmationText = affirmationVM.currentAffirmation?.text ?? "I am worthy of all good things in this life."
                VStack(spacing: 20) {
                    if isRecording && recordingVM.speechService.isRecognizing {
                        // Speech mode: words light up as recognised
                        HighlightedAffirmationText(
                            affirmation: affirmationText,
                            recognizedWords: recordingVM.speechService.recognizedWords
                        )
                        .padding(.horizontal, 36)
                        .transition(textTransition)
                    } else {
                        // Idle / voice-only mode: staggered entrance
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

                    // Sub-label row
                    if isRecording {
                        if recordingVM.speechService.isRecognizing {
                            // Word count progress + threshold indicator
                            let total = affirmationText.components(separatedBy: " ").filter { !$0.isEmpty }.count
                            let matched = HighlightedAffirmationText(
                                affirmation: affirmationText,
                                recognizedWords: recordingVM.speechService.recognizedWords
                            ).completionPercentage
                            let matchedCount = Int(matched * Double(total))
                            VStack(spacing: 8) {
                                if recordingVM.thresholdReached {
                                    // Celebration state — show for 0.5s before advancing
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
                                    // Volume gate indicator
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
                            // Voice-level fallback feedback
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

            // Voice level ring (only while recording)
            if isRecording {
                CircularVoiceDetector(
                    voiceLevel: recordingVM.voiceLevel,
                    threshold: affirmationVM.voiceThreshold
                )
                .transition(textTransition)
                .padding(.bottom, 16)
            }

            Spacer()

            // Single morphing button: "Tap to speak" → waveform → "Continue"
            actionButton
                .padding(.horizontal, 20)
                .padding(.bottom, 52)
        }
        .onDisappear {
            recordingVM.stopRecording()
            isRecording = false
        }
    }

    // MARK: - Page 3: Thanks for checking in
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

    // MARK: - Page 4: How do you feel?
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

    // MARK: - Page 5: Calendar / Trends
    private var calendarScreen: some View {
        ZStack {
            Color(red: 0.97, green: 0.96, blue: 0.94).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    HStack {
                        Button(action: { go(0) }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 15, weight: .medium))
                                Text("Home")
                                    .font(.system(size: 17))
                            }
                            .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                        }
                        Spacer()
                        Button(action: {}) {
                            HStack(spacing: 4) {
                                Text("Week")
                                    .font(.system(size: 17))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 13))
                            }
                            .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                            .padding(.bottom, 2)
                            .overlay(Rectangle().frame(height: 1)
                                .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2).opacity(0.4)),
                                alignment: .bottom)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 60)
                    .padding(.bottom, 24)

                    VStack(spacing: 6) {
                        Text(currentWeekRange)
                            .font(.system(size: 28, weight: .regular, design: .serif))
                            .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
                        Text("\(weekCheckIns) check-ins")
                            .font(.system(size: 15))
                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                    }
                    .padding(.bottom, 24)

                    EmotionGridCard()
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)

                    VStack(alignment: .leading, spacing: 0) {
                        Text(weeklyInsight)
                            .font(.system(size: 26, weight: .semibold, design: .serif))
                            .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.12))
                            .lineSpacing(4)
                            .padding(24)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)

                    Text("Building a ritual around self-care is proven to enhance emotional resilience, reduce stress, and promote overall well-being by creating consistent moments of intentional rest and reflection.")
                        .font(.system(size: 15))
                        .foregroundColor(Color(red: 0.35, green: 0.35, blue: 0.35))
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .padding(24)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 40)
                }
            }
        }
    }

    // MARK: - Lavender page helpers
    private var lavenderBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.82, green: 0.84, blue: 0.97),
                Color(red: 0.72, green: 0.74, blue: 0.92)
            ],
            startPoint: .top, endPoint: .bottom
        )
    }
    private var darkText: Color { Color(red: 0.08, green: 0.08, blue: 0.14) }
    private var suggestedFeeling: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let options = ["present", "calm", "grounded", "at ease", "peaceful"]
        return options[hour % options.count]
    }

    // MARK: - Dark nav (for lavender pages 3 + 4)
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

    // MARK: - Shared flow nav
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

    // MARK: - Morphing action button (page 2)
    // "Tap to speak" → waveform (recording) → "Continue" (complete)
    private var actionButton: some View {
        let isComplete = recordingVM.completionPercentage >= 1.0 || recordingVM.readyToAdvance

        return ZStack {
            if isRecording && !isComplete {
                // Recording state: white circle with waveform
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
                // Complete: full-width "Continue" pill
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
                // Idle: white circle mic icon
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

    // MARK: - Morning/night routing
    @State private var isMorningOverride: Int = UserDefaults.standard.integer(forKey: "debug_time_mode")
    // 0 = auto, 1 = morning, 2 = evening

    private var isMorning: Bool {
        #if DEBUG
        if isMorningOverride == 1 { return true }
        if isMorningOverride == 2 { return false }
        #endif
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 5 && hour < 17
    }

    private func navigateAfterFeeling() {
        if isMorning {
            Task { await intentionsVM.loadToday() }
            go(6)   // Morning: intentions input
        } else {
            Task { await intentionsVM.loadToday() }  // load to show completion in review
            go(8)   // Night: day review
        }
    }

    // MARK: - Inline recording
    private func startInlineRecording() {
        withAnimation(.easeInOut(duration: 0.38)) { isRecording = true }
        let affirmationText = affirmationVM.currentAffirmation?.text ?? "I am worthy of all good things in this life."
        recordingVM.startRecording(threshold: affirmationVM.voiceThreshold, affirmation: affirmationText)
        HapticManager.impact(.medium)
    }

    // MARK: - Text transition
    private var textTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .offset(y: 14)),
            removal:   .opacity.combined(with: .offset(y: -14))
        )
    }

    // MARK: - Helpers
    private var isEvening: Bool {
        Calendar.current.component(.hour, from: Date()) >= 17
    }

    // "Good Night" → "Good\nNight\nJH" — one word per line
    private var greetingStacked: String {
        let words = homeVM.greeting.components(separatedBy: " ")
        let lines = words + (homeVM.userName.isEmpty ? [] : [homeVM.userName])
        return lines.joined(separator: "\n")
    }

    private let feelingOptions = [
        "I feel more in tune",
        "I feel a shift, but it's still settling",
        "I feel the same and that's okay",
        "Not sure, I need a bit more time",
    ]

    private var currentWeekRange: String {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let startOffset = -(weekday - 2 + 7) % 7
        guard let start = calendar.date(byAdding: .day, value: startOffset, to: today),
              let end   = calendar.date(byAdding: .day, value: 6, to: start) else { return "" }
        let f = DateFormatter(); f.dateFormat = "d MMM"
        let y = DateFormatter(); y.dateFormat = "yyyy"
        return "\(f.string(from: start))–\(f.string(from: end)) \(y.string(from: today))"
    }

    private var weekCheckIns: Int { min(UserDefaults.standard.loadSettings().totalCompletions, 21) }

    private var weeklyInsight: String {
        UserDefaults.standard.loadSettings().totalCompletions > 5
            ? "This week you've been shifting your energy and experiencing more joy"
            : "You're building something powerful. Keep showing up."
    }

    private func startFlow() {
        let settings = UserDefaults.standard.loadSettings()
        if !storeKit.isPremium && settings.freeAffirmationsUsed >= Constants.freeAffirmationLimit {
            showPaywall = true; return
        }
        HapticManager.impact(.medium)
        go(1)
    }

    private func finishFlow() {
        recordingVM.stopRecording()
        isRecording = false
        homeVM.loadUserData()
        selectedFeeling = nil
        go(0)
    }

    private func go(_ p: Int) {
        let crossingBoundary = (page <= 2 && p >= 3) || (page >= 3 && p <= 2)

        if crossingBoundary {
            // Gradient ↔ Lavender: fade in lavender bridge, swap page, fade bridge out
            withAnimation(.easeIn(duration: 0.35)) { bridgeOpacity = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
                page = p
                withAnimation(.easeOut(duration: 0.55)) { bridgeOpacity = 0 }
            }
        } else if page >= 3 && p >= 3 {
            // Lavender → Lavender: already smooth, swap directly
            page = p
        } else {
            // Gradient → Gradient: standard fade
            withAnimation(.easeIn(duration: 0.3)) { pageOpacity = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                page = p
                withAnimation(.easeOut(duration: 0.45)) { pageOpacity = 1 }
            }
        }
    }
}

// MARK: - Page text entrance modifier
struct PageTextEntrance: ViewModifier {
    let page: Int
    let targetPage: Int
    @State private var visible = false

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 18)
            .onChange(of: page) { _, newPage in
                if newPage == targetPage {
                    visible = false
                    withAnimation(.easeOut(duration: 0.45).delay(0.15)) {
                        visible = true
                    }
                } else {
                    withAnimation(.easeIn(duration: 0.2)) {
                        visible = false
                    }
                }
            }
            .onAppear {
                if page == targetPage {
                    withAnimation(.easeOut(duration: 0.45).delay(0.15)) {
                        visible = true
                    }
                }
            }
    }
}

// MARK: - Emotion Grid Card
struct EmotionGridCard: View {
    private let emotions: [(name: String, color: Color, dots: [CGFloat])] = [
        ("Calm",     Color(red: 0.75, green: 0.78, blue: 0.92), [0.6, 0.8, 0,   0.9, 0.7, 0.4, 0]),
        ("Joy",      Color(red: 0.93, green: 0.72, blue: 0.18), [0.9, 0.7, 0,   1.0, 0.8, 0.5, 0]),
        ("Surprise", Color(red: 0.72, green: 0.38, blue: 0.10), [0,   0.4, 0,   0.7, 0.9, 0,   0]),
        ("Fear",     Color(red: 0.60, green: 0.08, blue: 0.22), [0,   0,   0.8, 0,   0.5, 0,   0.7]),
        ("Sadness",  Color(red: 0.72, green: 0.82, blue: 0.80), [0,   0.5, 0.4, 0,   0,   0.2, 0]),
    ]
    private let days = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

    var body: some View {
        VStack(spacing: 14) {
            ForEach(emotions, id: \.name) { emotion in
                HStack(spacing: 0) {
                    Text(emotion.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(emotion.color.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .frame(width: 90, alignment: .leading)

                    Spacer()

                    HStack(spacing: 0) {
                        ForEach(0..<7, id: \.self) { i in
                            let intensity = emotion.dots[i]
                            ZStack {
                                if intensity > 0 {
                                    Circle()
                                        .fill(emotion.color)
                                        .frame(width: 8 + intensity * 16, height: 8 + intensity * 16)
                                } else {
                                    Text("–")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
                                }
                            }
                            .frame(width: 32, height: 32)
                        }
                    }
                }
            }

            HStack(spacing: 0) {
                Spacer().frame(width: 90)
                Spacer()
                HStack(spacing: 0) {
                    ForEach(days, id: \.self) { day in
                        Text(day)
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.55))
                            .frame(width: 32)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Staggered Text Animation
struct StaggeredText: View {
    let text: String
    let font: Font
    var color: Color = .white
    var lineSpacing: CGFloat = 4
    var alignment: TextAlignment = .center
    var trigger: Bool
    var baseDelay: Double = 0.0

    @State private var show = false

    var body: some View {
        VStack(spacing: lineSpacing) {
            ForEach(Array(text.components(separatedBy: "\n").enumerated()), id: \.offset) { index, line in
                Text(line)
                    .font(font)
                    .foregroundColor(color)
                    .multilineTextAlignment(alignment)
                    .opacity(show ? 1 : 0)
                    .offset(y: show ? 0 : 20)
                    // Only stagger the entrance; reset instantly on exit
                    .animation(
                        show ? .easeOut(duration: 0.8).delay(baseDelay + Double(index) * 0.25) : .none,
                        value: show
                    )
            }
        }
        .onAppear {
            if trigger {
                // Helper to ensure 'false' state is rendered before animating to 'true'
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    show = true
                }
            }
        }
        .onChange(of: trigger) { _, val in
            if val {
                show = false // Ensure reset
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    show = true
                }
            } else {
                show = false
            }
        }
    }
}

// MARK: - Progress Dashes (used on lavender pages)
struct ProgressDashes: View {
    let total: Int
    let filled: Int
    var color: Color = Color(red: 0.12, green: 0.12, blue: 0.18)
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color.opacity(i < filled ? 1.0 : 0.22))
                    .frame(width: 38, height: 4)
            }
        }
    }
}

// MARK: - Liquid Glass Mic Button (unused — kept for reference)
struct LiquidGlassMicButton: View {
    let action: () -> Void
    var size: CGFloat = 110
    var isRecording: Bool = false

    @State private var ripples: [RippleRing] = []
    @State private var isPressed = false

    var body: some View {
        ZStack {
            // Liquid blob animation — only shown while recording
            if isRecording {
                TimelineView(.animation) { timeline in
                    Canvas { context, canvasSize in
                        let time = timeline.date.timeIntervalSinceReferenceDate
                        let cx = canvasSize.width / 2
                        let cy = canvasSize.height / 2
                        context.addFilter(.blur(radius: 22))
                        // 4 orbiting blobs
                        for i in 0..<4 {
                            let angle = (Double(i) * 90 + time * 48) * .pi / 180
                            let drift = sin(time * 2.2 + Double(i) * 1.4) * 9
                            let r = canvasSize.width * 0.27 + drift
                            let bx = cx + cos(angle) * r
                            let by = cy + sin(angle) * r
                            let bs = canvasSize.width * (0.32 + sin(time * 2.6 + Double(i)) * 0.05)
                            context.fill(
                                Path(ellipseIn: CGRect(x: bx - bs/2, y: by - bs/2, width: bs, height: bs)),
                                with: .color(Color.white.opacity(0.42))
                            )
                        }
                        // Central blob
                        let cs = canvasSize.width * 0.5
                        context.fill(
                            Path(ellipseIn: CGRect(x: cx - cs/2, y: cy - cs/2, width: cs, height: cs)),
                            with: .color(Color.white.opacity(0.2))
                        )
                    }
                }
                .frame(width: size * 1.9, height: size * 1.9)
                .transition(.opacity)
            }

            // Ripple rings on tap
            ForEach(ripples) { ring in
                Circle()
                    .stroke(Color.white.opacity(ring.opacity), lineWidth: ring.lineWidth)
                    .frame(width: ring.diameter, height: ring.diameter)
                    .scaleEffect(ring.scale)
            }

            // Glass button
            Button(action: {
                triggerRipple()
                action()
            }) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: size, height: size)

                    // Inner highlight arc
                    Circle()
                        .trim(from: 0.0, to: 0.45)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.6), Color.white.opacity(0.0)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                        )
                        .frame(width: size - 4, height: size - 4)
                        .rotationEffect(.degrees(-45))

                    // Outer rim
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        .frame(width: size, height: size)

                    // Icon
                    Image(systemName: isRecording ? "waveform" : "mic.fill")
                        .font(.system(size: size * 0.3, weight: .regular))
                        .foregroundColor(.white)
                        .scaleEffect(isPressed ? 0.88 : 1.0)
                        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
                }
                .shadow(color: .black.opacity(0.22), radius: 22, y: 10)
                .scaleEffect(isPressed ? 0.94 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.65), value: isPressed)
            }
            .buttonStyle(PlainButtonStyle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded   { _ in isPressed = false }
            )
        }
    }

    private func triggerRipple() {
        for i in 0..<3 {
            let delay = Double(i) * 0.2
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let ring = RippleRing(startDiameter: size)
                ripples.append(ring)
                withAnimation(.easeOut(duration: 1.2)) {
                    if let idx = ripples.firstIndex(where: { $0.id == ring.id }) {
                        ripples[idx].scale   = 2.8
                        ripples[idx].opacity = 0
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                    ripples.removeAll { $0.id == ring.id }
                }
            }
        }
    }
}
