import SwiftUI
import Combine

@MainActor
class RecordingViewModel: ObservableObject {
    @Published var voiceLevel: Double = 0
    @Published var feedback = "Speak clearly and with intention"
    @Published var feedbackColor = Color.white.opacity(0.8)
    @Published var thresholdReached = false
    @Published var secondsHeld: Double = 0
    // Used only by the voice-level fallback path (speech mode uses speechService.completionPercentage)
    @Published var readyToAdvance = false
    // Forwarded from speechService so SwiftUI onChange on HomeView fires correctly
    @Published var completionPercentage: Double = 0

    let speechService = SpeechRecognitionService()

    private let voiceService = VoiceService()
    private var cancellables = Set<AnyCancellable>()
    private var usingSpeech = false

    var threshold: Double = 60

    init() {
        voiceService.$voiceLevel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] level in
                guard let self, !self.usingSpeech else { return }
                self.voiceLevel = level
                self.updateFeedback(level: level)
            }
            .store(in: &cancellables)

        voiceService.onThresholdReached = { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, !self.usingSpeech else { return }
                self.thresholdReached = true
                HapticManager.successCelebration()
                self.readyToAdvance = true
            }
        }

        speechService.$voiceLevel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] level in
                guard let self, self.usingSpeech else { return }
                self.voiceLevel = level
                self.updateFeedback(level: level)
            }
            .store(in: &cancellables)

        speechService.$completionPercentage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] pct in
                self?.completionPercentage = pct
            }
            .store(in: &cancellables)
    }

    // MARK: - Start

    func startRecording(threshold: Double, affirmation: String = "") {
        self.threshold = threshold
        thresholdReached = false
        readyToAdvance = false

        if speechService.permissionGranted {
            usingSpeech = true
            do {
                speechService.voiceThreshold = threshold
                try speechService.startRecognition(affirmation: affirmation)
            } catch {
                usingSpeech = false
                startVoiceFallback(threshold: threshold)
                print("RecordingViewModel: speech recognition failed, using fallback — \(error)")
            }
        } else {
            usingSpeech = false
            startVoiceFallback(threshold: threshold)
        }
    }

    private func startVoiceFallback(threshold: Double) {
        voiceService.threshold = threshold
        voiceService.startMonitoring()
    }

    // MARK: - Stop

    func stopRecording() {
        if usingSpeech {
            speechService.stopRecognition()
        } else {
            voiceService.stopMonitoring()
        }
        voiceLevel = 0
    }

    func resetSession() {
        thresholdReached = false
        readyToAdvance = false
        completionPercentage = 0
    }

    // MARK: - Feedback

    private func updateFeedback(level: Double) {
        if level < threshold * 0.3 {
            feedback = "I can't hear you yet... speak up!"
            feedbackColor = Color.white.opacity(0.6)
        } else if level < threshold * 0.6 {
            feedback = "Louder! You've got this!"
            feedbackColor = Color.orange
        } else if level < threshold {
            feedback = "Almost there! Keep going!"
            feedbackColor = Color.yellow
        } else if level < threshold * 1.3 {
            feedback = "Yes! That's the energy! 🔥"
            feedbackColor = Color.green
        } else {
            feedback = "QUEEN ENERGY! 👑"
            feedbackColor = Color(hex: "#FFD700")
        }
    }
}
