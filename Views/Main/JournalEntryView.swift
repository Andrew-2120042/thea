import SwiftUI

struct JournalEntryView: View {
    @ObservedObject var viewModel: JournalViewModel
    let feeling: String?
    let onComplete: () -> Void
    let onSkip: () -> Void

    @FocusState private var isFocused: Bool

    private var darkText: Color { Color(red: 0.08, green: 0.08, blue: 0.14) }
    private var mutedText: Color { Color(red: 0.42, green: 0.42, blue: 0.48) }

    private var wordCount: Int {
        viewModel.entry.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }

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

                VStack(spacing: 20) {
                    // Title
                    Text("Before you sleep...")
                        .font(.system(size: 30, weight: .regular, design: .serif))
                        .foregroundColor(darkText)
                        .multilineTextAlignment(.center)
                        .padding(.top, 24)

                    // Prompt — tap to rotate
                    Button(action: { viewModel.rotatePrompt() }) {
                        HStack(spacing: 8) {
                            Text(viewModel.currentPrompt)
                                .font(.system(size: 17, weight: .medium, design: .serif))
                                .foregroundColor(darkText)
                                .multilineTextAlignment(.center)
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 13))
                                .foregroundColor(mutedText)
                        }
                        .padding(.horizontal, 36)
                    }

                    // Text editor
                    ZStack(alignment: .topLeading) {
                        if viewModel.entry.isEmpty {
                            Text("Tap to write...")
                                .font(.system(size: 16))
                                .foregroundColor(mutedText.opacity(0.7))
                                .padding(.horizontal, 4)
                                .padding(.top, 8)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $viewModel.entry)
                            .font(.system(size: 16))
                            .foregroundColor(darkText)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .frame(minHeight: 140, maxHeight: 200)
                            .focused($isFocused)
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 24)
                    .onTapGesture { isFocused = true }

                    // Word count + tip
                    HStack {
                        Text("💡 2–3 sentences is perfect.")
                            .font(.system(size: 13))
                            .foregroundColor(mutedText)
                        Spacer()
                        if wordCount > 0 {
                            Text("\(wordCount) words")
                                .font(.system(size: 12))
                                .foregroundColor(mutedText.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 28)
                }

                Spacer()

                // Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        Task {
                            await viewModel.save(feeling: feeling)
                            onComplete()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text(viewModel.entry.isEmpty ? "Skip for tonight" : "Save & Sleep Well")
                                .font(.system(size: 17, weight: .semibold))
                            Image(systemName: viewModel.entry.isEmpty ? "arrow.right" : "moon.stars.fill")
                                .font(.system(size: 15))
                        }
                        .foregroundColor(darkText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 72)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                    }
                    .buttonStyle(PlainButtonStyle())

                    if !viewModel.entry.isEmpty {
                        Button(action: onSkip) {
                            Text("Skip without saving")
                                .font(.system(size: 15))
                                .foregroundColor(darkText.opacity(0.5))
                                .underline()
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            Task { await viewModel.load(feeling: feeling) }
        }
    }
}
