import UIKit

struct HapticManager {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    static func successCelebration() {
        Task {
            impact(.heavy)
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            notification(.success)
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s
            impact(.light)
        }
    }
}
