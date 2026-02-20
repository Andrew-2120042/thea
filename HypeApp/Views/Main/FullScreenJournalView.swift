import SwiftUI
import PhotosUI

struct FullScreenJournalView: View {
    @ObservedObject var viewModel: JournalViewModel
    @Environment(\.dismiss) var dismiss

    @State private var showPromptSelector = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showPrompt = true
    @State private var showMoodPicker = false
    @State private var showColorPicker = false
    @State private var selectedMood: (emoji: String, name: String)?
    @State private var selectedColor: Color = Color(red: 0.82, green: 0.84, blue: 0.97)
    @FocusState private var isTextFieldFocused: Bool
    @StateObject private var voiceRecorder = VoiceRecorder()

    let feeling: String?
    let onSave: () -> Void

    private var darkText: Color { Color(red: 0.08, green: 0.08, blue: 0.14) }
    private var mutedText: Color { Color(red: 0.42, green: 0.42, blue: 0.48) }

    private let moods = [
        ("😢", "Sad"),
        ("🙁", "Low"),
        ("😐", "Okay"),
        ("😌", "Good"),
        ("😄", "Great")
    ]

    private let backgroundColors = [
        ("Lavender", Color(red: 0.82, green: 0.84, blue: 0.97)),
        ("Peach", Color(red: 1.0, green: 0.89, blue: 0.77)),
        ("Mint", Color(red: 0.78, green: 0.95, blue: 0.89)),
        ("Rose", Color(red: 1.0, green: 0.84, blue: 0.88)),
        ("Sky", Color(red: 0.68, green: 0.85, blue: 0.90)),
        ("Cream", Color(red: 0.98, green: 0.96, blue: 0.90))
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [selectedColor, selectedColor.opacity(0.85)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                topHeaderBar
                if voiceRecorder.isRecording {
                    recordingIndicator
                }
                if let mood = selectedMood {
                    moodPill(emoji: mood.emoji, name: mood.name)
                }
                currentPromptSection
                textEditorSection
                if isTextFieldFocused { bottomToolbar }
            }
        }
        .onAppear { isTextFieldFocused = true }
        .sheet(isPresented: $showPromptSelector) {
            PromptSelectorSheet(viewModel: viewModel, showPrompt: $showPrompt)
        }
        .confirmationDialog("How are you feeling?", isPresented: $showMoodPicker, titleVisibility: .visible) {
            ForEach(Array(moods.enumerated()), id: \.offset) { idx, mood in
                Button("\(mood.0) \(mood.1)") {
                    selectedMood = mood
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Choose background color", isPresented: $showColorPicker, titleVisibility: .visible) {
            ForEach(backgroundColors, id: \.0) { color in
                Button(color.0) {
                    selectedColor = color.1
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Top Header
    private var topHeaderBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 20))
                    .foregroundColor(darkText)
                    .frame(width: 44, height: 44)
            }

            VStack(spacing: 2) {
                Text("Tonight")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(darkText)
                Text(Date(), style: .time)
                    .font(.system(size: 14))
                    .foregroundColor(mutedText)
            }

            Spacer()

            Button(action: {
                Task {
                    await viewModel.save(feeling: feeling)
                    onSave()
                }
            }) {
                Image(systemName: "checkmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(red: 0.07, green: 0.72, blue: 0.51))
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Recording Indicator
    private var recordingIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .opacity(0.8)
            Text("Recording...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(darkText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical: 8)
        .background(Color.white.opacity(0.6))
        .clipShape(Capsule())
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Mood Pill
    private func moodPill(emoji: String, name: String) -> some View {
        HStack(spacing: 8) {
            Text(emoji)
                .font(.system(size: 18))
            VStack(alignment: .leading, spacing: 2) {
                Text("MOOD")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(darkText.opacity(0.6))
                    .tracking(1)
                Text(name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(darkText)
            }
            Spacer()
            Button(action: { selectedMood = nil }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(mutedText.opacity(0.6))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.5))
        .clipShape(Capsule())
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Prompt Section
    private var currentPromptSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if showPrompt {
                HStack {
                    Text(viewModel.currentPrompt)
                        .font(.system(size: 18, weight: .medium, design: .serif))
                        .foregroundColor(darkText)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showPrompt = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(mutedText.opacity(0.7))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 10) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showPrompt = true
                    }
                    viewModel.rotatePrompt()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 13))
                        Text("New Prompt")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(darkText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.5))
                    .clipShape(Capsule())
                }

                Button(action: { showPromptSelector = true }) {
                    Text("See All")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(darkText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.white.opacity(0.5))
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Text Editor
    private var textEditorSection: some View {
        ZStack(alignment: .topLeading) {
            if viewModel.entry.isEmpty {
                Text("Start writing...")
                    .font(.system(size: 18))
                    .foregroundColor(mutedText.opacity(0.6))
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .allowsHitTesting(false)
            }
            TextEditor(text: $viewModel.entry)
                .font(.system(size: 18))
                .foregroundColor(darkText)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .focused($isTextFieldFocused)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Bottom Toolbar
    private var bottomToolbar: some View {
        HStack(spacing: 8) {
            toolbarButton(.emoji) {
                showMoodPicker = true
            }

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                toolbarButtonContent(.photo)
            }
            .onChange(of: selectedPhoto) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        // Photo loaded - V2 will display it in journal
                        print("Photo loaded: \(data.count) bytes")
                    }
                }
            }

            toolbarButton(JournalToolbarAction(icon: "paintpalette", id: "color")) {
                showColorPicker = true
            }

            toolbarButton(.voice) {
                Task {
                    if voiceRecorder.isRecording {
                        voiceRecorder.stopRecording()
                        let transcription = voiceRecorder.getTranscriptionAndReset()
                        if !transcription.isEmpty {
                            if !viewModel.entry.isEmpty && !viewModel.entry.hasSuffix("\n") {
                                viewModel.entry += " "
                            }
                            viewModel.entry += transcription
                        }
                    } else {
                        let hasPermission = await voiceRecorder.requestPermissions()
                        if hasPermission {
                            try? await voiceRecorder.startRecording()
                        }
                    }
                }
            }

            Menu {
                Button(action: { insertBulletPoint() }) {
                    Label("Bullet List", systemImage: "list.bullet")
                }
                Button(action: { insertNumberedPoint() }) {
                    Label("Numbered List", systemImage: "list.number")
                }
            } label: {
                toolbarButtonContent(.bulletList)
            }

            Spacer()

            toolbarButton(.keyboard) {
                isTextFieldFocused = false
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.5))
        .clipShape(Capsule())
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func toolbarButton(_ action: JournalToolbarAction, handler: @escaping () -> Void) -> some View {
        Button(action: handler) {
            toolbarButtonContent(action)
        }
    }

    private func toolbarButton(_ action: (icon: String, id: String), handler: @escaping () -> Void) -> some View {
        Button(action: handler) {
            Image(systemName: action.icon)
                .font(.system(size: 20))
                .foregroundColor(darkText)
                .frame(width: 40, height: 40)
        }
    }

    private func toolbarButtonContent(_ action: JournalToolbarAction) -> some View {
        let isVoiceRecording = action == .voice && voiceRecorder.isRecording

        return Image(systemName: action.icon)
            .font(.system(size: 20))
            .foregroundColor(isVoiceRecording ? .red : darkText)
            .frame(width: 40, height: 40)
            .background(
                isVoiceRecording ? Circle().fill(Color.red.opacity(0.1)) : nil
            )
    }

    private func insertBulletPoint() {
        if !viewModel.entry.isEmpty && !viewModel.entry.hasSuffix("\n") {
            viewModel.entry += "\n"
        }
        viewModel.entry += "• "
    }

    private func insertNumberedPoint() {
        if !viewModel.entry.isEmpty && !viewModel.entry.hasSuffix("\n") {
            viewModel.entry += "\n"
        }
        let lines = viewModel.entry.components(separatedBy: "\n")
        let numbered = lines.filter { $0.trimmingCharacters(in: .whitespaces).first?.isNumber == true }
        viewModel.entry += "\(numbered.count + 1). "
    }
}

// MARK: - Prompt Selector
struct PromptSelectorSheet: View {
    @ObservedObject var viewModel: JournalViewModel
    @Binding var showPrompt: Bool
    @Environment(\.dismiss) var dismiss

    private var darkText: Color { Color(red: 0.08, green: 0.08, blue: 0.14) }

    private let allPrompts = [
        "What's one thing you're grateful for today?",
        "What did you learn today?",
        "What challenged you today?",
        "What surprised you today?",
        "What made you smile today?",
        "What would you do differently tomorrow?",
        "What's one small win from today?",
        "What are you proud of today?",
        "What did you accomplish today?",
        "What made today special?"
    ]

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.82, green: 0.84, blue: 0.97), Color(red: 0.72, green: 0.74, blue: 0.92)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(allPrompts, id: \.self) { prompt in
                            Button(action: {
                                viewModel.currentPrompt = prompt
                                showPrompt = true
                                dismiss()
                            }) {
                                Text(prompt)
                                    .font(.system(size: 16))
                                    .foregroundColor(darkText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(16)
                                    .background(Color.white.opacity(0.5))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Choose Prompt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(darkText)
                }
            }
        }
    }
}
