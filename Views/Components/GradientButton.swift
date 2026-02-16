import SwiftUI

struct GradientButton: View {
    let title: String
    let action: () -> Void
    var gradient: LinearGradient = LinearGradient(
        colors: [HypeColors.primary, HypeColors.secondary],
        startPoint: .leading,
        endPoint: .trailing
    )
    var isLoading = false
    var disabled = false

    var body: some View {
        Button(action: {
            if !disabled && !isLoading {
                HapticManager.impact(.medium)
                action()
            }
        }) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Group {
                if disabled {
                    Color.gray.opacity(0.5)
                } else {
                    gradient
                }
            })
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: HypeColors.primary.opacity(0.3), radius: 12, y: 6)
        }
        .disabled(disabled || isLoading)
        .buttonStyle(GlassButtonStyle())
    }
}

// MARK: - White/Glass Button
struct GlassOutlineButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.impact(.light)
            action()
        }) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                )
        }
        .buttonStyle(GlassButtonStyle())
    }
}
