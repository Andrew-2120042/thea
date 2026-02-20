import SwiftUI

struct TodaysIntentionsView: View {
    @ObservedObject var viewModel: IntentionsViewModel
    let todaysAffirmation: String?
    let onDone: () -> Void

    private var darkText: Color { Color(red: 0.08, green: 0.08, blue: 0.14) }
    private var mutedText: Color { Color(red: 0.42, green: 0.42, blue: 0.48) }

    var body: some View {
        ZStack {
            Color(red: 0.97, green: 0.96, blue: 0.94)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Nav
                HStack {
                    Button(action: onDone) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 15, weight: .medium))
                            Text("Home")
                                .font(.system(size: 17))
                        }
                        .foregroundColor(darkText)
                    }
                    Spacer()
                    Text(Date(), style: .date)
                        .font(.system(size: 15))
                        .foregroundColor(mutedText)
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 20)

                Divider().padding(.horizontal, 24)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Intentions
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Your Focus Today")
                                .font(.system(size: 26, weight: .regular, design: .serif))
                                .foregroundColor(darkText)

                            if viewModel.intentions.isEmpty {
                                Text("No intentions set for today.")
                                    .font(.system(size: 16))
                                    .foregroundColor(mutedText)
                            } else {
                                ForEach(viewModel.intentions) { intention in
                                    IntentionRow(intention: intention) {
                                        Task { await viewModel.toggleCompletion(id: intention.id) }
                                    }
                                }

                                let done = viewModel.intentions.filter { $0.completed }.count
                                let total = viewModel.intentions.count
                                Text("\(done) of \(total) complete")
                                    .font(.system(size: 13))
                                    .foregroundColor(mutedText)
                                    .padding(.top, 4)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 28)

                        Divider().padding(.horizontal, 24)

                        // Affirmation reminder
                        if let affirmation = todaysAffirmation {
                            VStack(spacing: 12) {
                                Text("You said:")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(mutedText)

                                Text("\"\(affirmation)\"")
                                    .font(.system(size: 20, weight: .regular, design: .serif))
                                    .foregroundColor(darkText)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)

                                Text("Now go prove it. 🔥")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Color(red: 0.55, green: 0.36, blue: 0.96))
                            }
                            .padding(.vertical, 8)
                        }

                        // Done button
                        Button(action: onDone) {
                            Text("Done")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(darkText)
                                .frame(maxWidth: .infinity)
                                .frame(height: 72)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 24)
                        .padding(.bottom, 48)
                    }
                }
            }
        }
    }
}

// MARK: - Intention row with checkbox
private struct IntentionRow: View {
    let intention: Intention
    let onToggle: () -> Void

    private var darkText: Color { Color(red: 0.08, green: 0.08, blue: 0.14) }
    private var green: Color { Color(red: 0.07, green: 0.72, blue: 0.51) }

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(intention.completed ? green : Color(red: 0.82, green: 0.82, blue: 0.84), lineWidth: 2)
                        .frame(width: 26, height: 26)
                    if intention.completed {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(green)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(intention.text)
                        .font(.system(size: 16))
                        .foregroundColor(darkText)
                        .strikethrough(intention.completed, color: darkText.opacity(0.5))

                    if let completedAt = intention.completedAt {
                        Text("Done at \(completedAt, style: .time)")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                    }
                }

                Spacer()
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: intention.completed)
    }
}
