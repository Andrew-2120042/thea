import SwiftUI

struct CircularVoiceDetector: View {
    let voiceLevel: Double
    let threshold: Double

    @State private var animationPhase: Double = 0

    var body: some View {
        ZStack {
            // Animated outer rings
            ForEach(0..<4) { index in
                Circle()
                    .stroke(lineWidth: 1.5)
                    .foregroundColor(.white.opacity(ringOpacity(index: index)))
                    .frame(width: ringSize(index: index), height: ringSize(index: index))
                    .scaleEffect(ringScale(index: index))
                    .animation(
                        .easeInOut(duration: 1.2 + Double(index) * 0.2)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.15),
                        value: voiceLevel
                    )
            }

            // Background circle
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 180, height: 180)

            // Main ring
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                .frame(width: 180, height: 180)

            // Voice level arc
            Circle()
                .trim(from: 0, to: min(voiceLevel / 100, 1.0))
                .stroke(
                    voiceLevelGradient,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 174, height: 174)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.15, dampingFraction: 0.8), value: voiceLevel)

            // Threshold marker
            ThresholdMarker(threshold: threshold)
                .frame(width: 180, height: 180)

            // Center content
            VStack(spacing: 4) {
                Image(systemName: voiceLevel > threshold * 0.5 ? "mic.fill" : "mic")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .scaleEffect(voiceLevel > threshold * 0.5 ? 1.1 : 1.0)
                    .animation(.spring(response: 0.2), value: voiceLevel)

                Text("\(Int(voiceLevel))%")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
            }
        }
        .frame(width: 220, height: 220)
    }

    // MARK: - Ring Helpers
    private func ringSize(index: Int) -> CGFloat {
        180 + CGFloat(index + 1) * 28
    }

    private func ringOpacity(index: Int) -> Double {
        let base = 0.12 - Double(index) * 0.02
        let voiceBoost = (voiceLevel / 100) * 0.15
        return max(0.02, base + voiceBoost)
    }

    private func ringScale(index: Int) -> CGFloat {
        let boost = (voiceLevel / 100) * 0.15 * CGFloat(index + 1)
        return 1.0 + boost
    }

    // MARK: - Gradient
    private var voiceLevelGradient: AngularGradient {
        let color = voiceLevelColor
        return AngularGradient(
            colors: [color.opacity(0.3), color],
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(-90 + 360 * min(voiceLevel / 100, 1.0))
        )
    }

    private var voiceLevelColor: Color {
        if voiceLevel < threshold * 0.5 {
            return .white
        } else if voiceLevel < threshold {
            return Color.orange
        } else if voiceLevel < threshold * 1.3 {
            return Color.green
        } else {
            return Color(hex: "#FFD700")
        }
    }
}

// MARK: - Threshold Marker
struct ThresholdMarker: View {
    let threshold: Double

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = geo.size.width / 2
            let angle = (threshold / 100) * 360 - 90
            let radians = angle * .pi / 180
            let x = center.x + radius * cos(radians)
            let y = center.y + radius * sin(radians)

            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 8, height: 8)
                    .position(x: x, y: y)
            }
        }
    }
}
