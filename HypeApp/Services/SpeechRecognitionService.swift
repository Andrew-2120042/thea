import Speech
import AVFoundation

@MainActor
class SpeechRecognitionService: NSObject, ObservableObject {
    @Published var recognizedWords: [String] = []
    @Published var isRecognizing = false
    @Published var permissionGranted = false
    @Published var voiceLevel: Double = 0
    @Published var isAboveThreshold = false
    @Published var completionPercentage: Double = 0   // 0.0–1.0, updated on every word match

    var voiceThreshold: Double = 60

    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()

    private var accumulated: [String] = []
    private var affirmationWords: [String] = []   // set at start of each session
    private var lastAboveTime: Date?

    override init() {
        super.init()
        requestPermission()
    }

    func requestPermission() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor [weak self] in
                self?.permissionGranted = (status == .authorized)
            }
        }
    }

    func startRecognition(affirmation: String) throws {
        // Parse the target affirmation into normalised words
        affirmationWords = affirmation
            .lowercased()
            .components(separatedBy: " ")
            .filter { !$0.isEmpty }
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }

        // Reset session
        recognitionTask?.cancel()
        recognitionTask = nil
        accumulated = []
        recognizedWords = []
        completionPercentage = 0
        lastAboveTime = nil
        isAboveThreshold = false

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [.allowBluetoothHFP])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else {
            throw NSError(domain: "SpeechRecognition", code: -1)
        }

        recognitionRequest.shouldReportPartialResults = true
        if speechRecognizer?.supportsOnDeviceRecognition == true {
            recognitionRequest.requiresOnDeviceRecognition = true
        }

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            recognitionRequest.append(buffer)
            let level = Self.rmsLevel(from: buffer)
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.voiceLevel = level
                let above = level >= self.voiceThreshold
                self.isAboveThreshold = above
                if above { self.lastAboveTime = Date() }
            }
        }

        audioEngine.prepare()
        try audioEngine.start()
        isRecognizing = true

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self else { return }

                if let result {
                    let latestWords = result.bestTranscription.segments.map {
                        $0.substring.lowercased().trimmingCharacters(in: .punctuationCharacters)
                    }

                    let grace: Bool
                    if let t = self.lastAboveTime {
                        grace = Date().timeIntervalSince(t) <= 1.5
                    } else {
                        grace = false
                    }

                    if self.isAboveThreshold || grace {
                        var changed = false
                        for word in latestWords where !word.isEmpty {
                            if !self.accumulated.contains(word) {
                                self.accumulated.append(word)
                                changed = true
                            }
                        }
                        if changed {
                            self.recognizedWords = self.accumulated
                            // Update completionPercentage synchronously — SwiftUI observes this directly
                            self.completionPercentage = self.calculateCompletion()
                        }
                    }
                }

                if error != nil || result?.isFinal == true {
                    self.stopRecognition()
                }
            }
        }
    }

    func stopRecognition() {
        guard isRecognizing || audioEngine.isRunning else { return }
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isRecognizing = false
        isAboveThreshold = false
        voiceLevel = 0
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Completion

    private func calculateCompletion() -> Double {
        guard !affirmationWords.isEmpty else { return 0 }
        let matched = affirmationWords.filter { w in
            accumulated.contains { r in
                w == r || levenshtein(w, r) <= (max(w.count, r.count) <= 4 ? 1 : 2)
            }
        }.count
        return Double(matched) / Double(affirmationWords.count)
    }

    private func levenshtein(_ s1: String, _ s2: String) -> Int {
        let a = Array(s1), b = Array(s2)
        var dp = Array(0...b.count)
        for i in 1...max(a.count, 1) {
            guard i <= a.count else { break }
            var prev = dp[0]; dp[0] = i
            for j in 1...b.count {
                let temp = dp[j]
                dp[j] = a[i-1] == b[j-1] ? prev : 1 + min(prev, dp[j], dp[j-1])
                prev = temp
            }
        }
        return dp[b.count]
    }

    // MARK: - RMS voice level (0–100)
    private static func rmsLevel(from buffer: AVAudioPCMBuffer) -> Double {
        guard let data = buffer.floatChannelData?[0] else { return 0 }
        let count = Int(buffer.frameLength)
        guard count > 0 else { return 0 }
        var sum: Float = 0
        for i in 0..<count { sum += data[i] * data[i] }
        let rms = sqrt(sum / Float(count))
        let db = 20 * log10(max(rms, 1e-9))
        return max(0, min(100, Double((db + 80) / 0.8)))
    }
}
