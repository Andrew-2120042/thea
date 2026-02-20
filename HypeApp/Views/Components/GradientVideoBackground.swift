import SwiftUI
import AVKit

struct GradientVideoBackground: View {
    let gradient: LinearGradient
    var opacity: Double = 1.0

    var body: some View {
        ZStack {
            gradient
                .ignoresSafeArea()

            // Soft noise overlay for depth
            Rectangle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.05), Color.clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 400
                    )
                )
                .ignoresSafeArea()
                .blendMode(.overlay)
        }
        .opacity(opacity)
    }
}

// MARK: - Time-Based Gradient View
struct TimeBasedGradientBackground: View {
    var body: some View {
        GradientVideoBackground(gradient: currentGradient)
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
