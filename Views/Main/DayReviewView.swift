import SwiftUI

struct DayReviewView: View {
    @ObservedObject var intentionsVM: IntentionsViewModel
    let onContinue: () -> Void
    let onSkip: () -> Void

    private var darkText: Color { Color(red: 0.08, green: 0.08, blue: 0.14) }
    private var mutedText: Color { Color(red: 0.42, green: 0.42, blue: 0.48) }

    private var completedCount: Int { intentionsVM.intentions.filter { $0.completed }.count }
    private var totalCount: Int { intentionsVM.intentions.count }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.82, green: 0.84, blue: 0.97), Color(red: 0.72, green: 0.74, blue: 0.92)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Nav
                HStack {
                    Button(action: onSkip) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(darkText)
                            .frame(width: 44, height: 44)
                    }
                    Spacer()
                    ProgressDashes(total: 4, filled: 4)
                    Spacer()
                    Button(action: onSkip) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16))
                            .foregroundColor(darkText.opacity(0.7))
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Title
                        VStack(spacing: 6) {
                            Text("How was today?")
                                .font(.system(size: 32, weight: .regular, design: .serif))
                                .foregroundColor(darkText)

                            Text(totalCount > 0 ? "\(completedCount) of \(totalCount) intentions done" : "Evening check-in")
                                .font(.system(size: 15))
                                .foregroundColor(mutedText)
                        }
                        .multilineTextAlignment(.center)
                        .padding(.top, 28)

                        // Intentions list
                        if totalCount > 0 {
                            VStack(spacing: 10) {
                                ForEach(intentionsVM.intentions) { intention in
                                    ReviewIntentionRow(
                                        intention: intention,
                                        onToggle: {
                                            Task { await intentionsVM.toggleCompletion(id: intention.id) }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 24)
                        } else {
                            VStack(spacing: 8) {
                                Text("No intentions were set this morning.")
                                    .font(.system(size: 16))
                                    .foregroundColor(mutedText)
                                    .multilineTextAlignment(.center)
                                Text("That's okay — every day is a fresh start.")
                                    .font(.system(size: 14))
                                    .foregroundColor(mutedText.opacity(0.7))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 36)
                        }

                        // Summary badge
                        if completedCount > 0 {
                            HStack(spacing: 10) {
                                Text(completedCount == totalCount ? "🏆" : "💪")
                                    .font(.system(size: 24))
                                Text(completedCount == totalCount ? "You crushed it today!" : "Good progress — be proud.")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(darkText)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.45))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal, 24)
                        }

                        Spacer().frame(height: 20)
                    }
                }

                // Buttons
                VStack(spacing: 12) {
                    Button(action: onContinue) {
                        Text("Reflect on your day →")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(darkText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 72)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: onSkip) {
                        Text("Skip")
                            .font(.system(size: 16))
                            .foregroundColor(darkText.opacity(0.55))
                            .underline()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }
}

// MARK: - Row
private struct ReviewIntentionRow: View {
    let intention: Intention
    let onToggle: () -> Void

    private var green: Color { Color(red: 0.07, green: 0.72, blue: 0.51) }
    private var darkText: Color { Color(red: 0.08, green: 0.08, blue: 0.14) }

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(intention.completed ? green : Color(red: 0.75, green: 0.75, blue: 0.78), lineWidth: 2)
                        .frame(width: 26, height: 26)
                    if intention.completed {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(green)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(intention.text)
                        .font(.system(size: 15))
                        .foregroundColor(darkText)
                        .strikethrough(intention.completed, color: darkText.opacity(0.5))
                    if let t = intention.completedAt {
                        Text("Done at \(t, style: .time)")
                            .font(.system(size: 11))
                            .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                    }
                }

                Spacer()

                if !intention.completed {
                    Text("Tap to mark done")
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.55))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: intention.completed)
    }
}
