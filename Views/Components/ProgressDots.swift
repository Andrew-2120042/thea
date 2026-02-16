import SwiftUI

struct ProgressDots: View {
    let total: Int
    let current: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(dotColor(for: index))
                    .frame(width: index == current ? 20 : 8, height: 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: current)
            }
        }
    }

    private func dotColor(for index: Int) -> Color {
        if index == current {
            return .white
        } else if index < current {
            return .white.opacity(0.6)
        } else {
            return .white.opacity(0.25)
        }
    }
}
