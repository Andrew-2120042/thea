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

