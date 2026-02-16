import AVFoundation
import Combine

class VoiceService: NSObject, ObservableObject {
    @Published var voiceLevel: Double = 0
    @Published var isRecording = false

    private var audioRecorder: AVAudioRecorder?
    private var levelTimer: Timer?
    private var thresholdStartTime: Date?

    var threshold: Double = 60
    var sustainDuration: TimeInterval = 3.0
    var onThresholdReached: (() -> Void)?

    // MARK: - Start Monitoring
    func startMonitoring() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.allowBluetoothHFP, .defaultToSpeaker])
            try audioSession.setActive(true)

            let url = FileManager.default.temporaryDirectory.appendingPathComponent("hype_voice_temp.m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()

            isRecording = true
            thresholdStartTime = nil

            levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                self?.updateVoiceLevel()
            }
        } catch {
            print("VoiceService: Failed to start recording: \(error)")
        }
    }

    // MARK: - Stop Monitoring
    func stopMonitoring() {
        levelTimer?.invalidate()
        levelTimer = nil
        audioRecorder?.stop()
        audioRecorder = nil
        thresholdStartTime = nil

        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("VoiceService: Failed to deactivate session: \(error)")
        }

        DispatchQueue.main.async {
            self.isRecording = false
            self.voiceLevel = 0
        }
    }

    // MARK: - Level Update
    private func updateVoiceLevel() {
        audioRecorder?.updateMeters()
        let power = audioRecorder?.averagePower(forChannel: 0) ?? -160
        let peakPower = audioRecorder?.peakPower(forChannel: 0) ?? -160

        // Use a blend of average and peak for responsiveness
        let blendedPower = (power * 0.7) + (peakPower * 0.3)

        // Convert dB (-160 to 0) to 0-100 scale
        // Typical speaking voice is around -20 to -10 dB
        let normalised: Double = max(0, min(100, Double((blendedPower + 80) / 0.8)))

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.voiceLevel = normalised

            if normalised >= self.threshold {
                if self.thresholdStartTime == nil {
                    self.thresholdStartTime = Date()
                } else if let start = self.thresholdStartTime,
                          Date().timeIntervalSince(start) >= self.sustainDuration {
                    self.stopMonitoring()
                    self.onThresholdReached?()
                    self.thresholdStartTime = nil
                }
            } else {
                self.thresholdStartTime = nil
            }
        }
    }

    // MARK: - Request Permission
    static func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}
