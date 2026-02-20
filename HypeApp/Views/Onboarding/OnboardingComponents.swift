import SwiftUI

// MARK: - Shared Onboarding Header
@ViewBuilder
func onboardingHeader(step: Int, total: Int, onBack: @escaping () -> Void) -> some View {
    HStack(alignment: .center) {
        Button(action: onBack) {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
        }

        Spacer()

        ProgressDots(total: total, current: step)

        Spacer()

        // Balance spacer
        Color.clear.frame(width: 40, height: 40)
    }
    .padding(.horizontal, 20)
    .padding(.top, 16)
}
