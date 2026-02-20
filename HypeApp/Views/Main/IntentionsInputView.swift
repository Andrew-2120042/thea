import SwiftUI

struct IntentionsInputView: View {
    @ObservedObject var viewModel: IntentionsViewModel
    let feeling: String?
    let onContinue: () -> Void
    let onSkip: () -> Void

    @State private var newText = ""
    @FocusState private var isFocused: Bool

    private var darkText: Color { Color(red: 0.08, green: 0.08, blue: 0.14) }
    private var mutedText: Color { Color(red: 0.42, green: 0.42, blue: 0.48) }

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

                // Title
                VStack(spacing: 8) {
                    Text("What do you want to")
                        .font(.system(size: 30, weight: .regular, design: .serif))
                        .foregroundColor(darkText)
                    Text("focus on today?")
                        .font(.system(size: 30, weight: .regular, design: .serif))
                        .foregroundColor(darkText)
                }
                .multilineTextAlignment(.center)
                .padding(.top, 32)

                Text("Add up to 3 intentions")
                    .font(.system(size: 14))
                    .foregroundColor(mutedText)
                    .padding(.top, 8)

                // List
                VStack(spacing: 12) {
                    ForEach(Array(viewModel.intentions.enumerated()), id: \.element.id) { idx, item in
                        HStack(spacing: 12) {
                            Text("\(idx + 1)")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(mutedText)
                                .frame(width: 20)

                            Text(item.text)
                                .font(.system(size: 16))
                                .foregroundColor(darkText)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Button(action: { viewModel.removeIntention(at: idx) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(mutedText.opacity(0.6))
                                    .font(.system(size: 18))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.55))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    // Input row
                    if viewModel.intentions.count < 3 {
                        HStack(spacing: 12) {
                            Text("\(viewModel.intentions.count + 1)")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(mutedText)
                                .frame(width: 20)

                            TextField("Type an intention...", text: $newText)
                                .font(.system(size: 16))
                                .foregroundColor(darkText)
                                .focused($isFocused)
                                .submitLabel(.done)
                                .onSubmit { commitText() }

                            if !newText.isEmpty {
                                Button(action: commitText) {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .foregroundColor(darkText)
                                        .font(.system(size: 22))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.35))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(darkText.opacity(isFocused ? 0.25 : 0.0), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                // Feeling-based tip
                if let tip = tip(for: feeling) {
                    HStack(spacing: 8) {
                        Text("💡")
                        Text(tip)
                            .font(.system(size: 13))
                            .foregroundColor(mutedText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }

                Spacer()

                // Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        Task {
                            await viewModel.save(feeling: feeling)
                            onContinue()
                        }
                    }) {
                        Text(viewModel.intentions.isEmpty ? "Skip for now" : "Start My Day")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(darkText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 72)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                    }
                    .buttonStyle(PlainButtonStyle())

                    if !viewModel.intentions.isEmpty {
                        Button(action: onSkip) {
                            Text("Skip")
                                .font(.system(size: 16))
                                .foregroundColor(darkText.opacity(0.6))
                                .underline()
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }

    private func commitText() {
        viewModel.addIntention(text: newText)
        newText = ""
    }

    private func tip(for feeling: String?) -> String? {
        guard let f = feeling?.lowercased() else { return nil }
        if f.contains("more in tune") { return "Great energy! Perfect time for stretch goals." }
        if f.contains("shift") { return "Keep it balanced — 2 focused tasks is plenty." }
        if f.contains("same") { return "Be gentle with yourself. 1 essential task is enough." }
        return nil
    }
}
