import SwiftUI

// MARK: - Glass Mic Button with Water Ripple
struct GlassMicButton: View {
    let action: () -> Void
    var size: CGFloat = 120
    var isRecording: Bool = false

    @State private var ripples: [RippleRing] = []
    @State private var isPressed = false

    var body: some View {
        ZStack {
            // Water ripple rings (behind button)
            ForEach(ripples) { ring in
                Circle()
                    .stroke(Color.white.opacity(ring.opacity), lineWidth: ring.lineWidth)
                    .frame(width: ring.diameter, height: ring.diameter)
                    .scaleEffect(ring.scale)
            }

            // Outer soft glow ring (only when recording)
            if isRecording {
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: size * 1.6, height: size * 1.6)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isRecording)
            }

            // The button itself
            Button(action: {
                triggerRipple()
                action()
            }) {
                ZStack {
                    // Circle background — transparent with white border
                    Circle()
                        .fill(Color.white.opacity(0.08))
                    Circle()
                        .stroke(Color.white.opacity(0.35), lineWidth: 1.5)

                    // Mic icon
                    Image(systemName: isRecording ? "waveform" : "mic.fill")
                        .font(.system(size: size * 0.3, weight: .regular))
                        .foregroundColor(.white)
                        .scaleEffect(isPressed ? 0.88 : 1.0)
                        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
                }
                .frame(width: size, height: size)
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

    // MARK: - Ripple trigger
    private func triggerRipple() {
        for i in 0..<3 {
            let delay = Double(i) * 0.18
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let ring = RippleRing(startDiameter: size)
                ripples.append(ring)
                withAnimation(.easeOut(duration: 1.1)) {
                    if let idx = ripples.firstIndex(where: { $0.id == ring.id }) {
                        ripples[idx].scale   = 2.6
                        ripples[idx].opacity = 0
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
                    ripples.removeAll { $0.id == ring.id }
                }
            }
        }
    }
}

// MARK: - Ripple Ring Model
struct RippleRing: Identifiable {
    let id = UUID()
    let diameter: CGFloat
    var scale: CGFloat   = 1.0
    var opacity: Double  = 0.45
    var lineWidth: CGFloat = 1.2

    init(startDiameter: CGFloat) {
        self.diameter = startDiameter
    }
}
