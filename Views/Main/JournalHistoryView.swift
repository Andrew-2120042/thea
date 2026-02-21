import SwiftUI
import PhotosUI

struct JournalHistoryView: View {
    @ObservedObject var viewModel: JournalViewModel
    @State private var journals: [DailyJournal] = []
    @State private var selectedJournal: DailyJournal?
    @State private var showNewEntry = false
    @State private var searchText = ""

    var body: some View {
        ZStack {
            Color(hex: "#FAF9F6")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Journal")
                        .font(.system(size: 26, weight: .regular, design: .serif))
                        .foregroundColor(Color(hex: "#1F2937"))

                    Spacer()

                    Button(action: { showNewEntry = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color(hex: "#8B5CF6"))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)

                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color(hex: "#9CA3AF"))

                    TextField("Search journals...", text: $searchText)
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#1F2937"))
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                // Journal list
                if journals.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredJournals) { journal in
                                JournalEntryCard(journal: journal)
                                    .onTapGesture {
                                        selectedJournal = journal
                                    }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .sheet(item: $selectedJournal) { journal in
            JournalDetailView(journal: journal)
        }
        .fullScreenCover(isPresented: $showNewEntry) {
            FullScreenJournalView(
                viewModel: viewModel,
                feeling: nil,
                onSave: {
                    showNewEntry = false
                    Task {
                        await loadJournals()
                    }
                }
            )
        }
        .onAppear {
            Task {
                await loadJournals()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Text("📝")
                .font(.system(size: 64))

            Text("No journal entries yet")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "#1F2937"))

            Text("Start journaling to track your thoughts and reflections")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "#6B7280"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: { showNewEntry = true }) {
                Text("Write First Entry")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(hex: "#8B5CF6"))
                    .cornerRadius(12)
            }
            .padding(.top, 16)

            Spacer()
        }
    }

    private var filteredJournals: [DailyJournal] {
        if searchText.isEmpty {
            return journals
        } else {
            return journals.filter { journal in
                journal.entry.lowercased().contains(searchText.lowercased()) ||
                (journal.prompt?.lowercased().contains(searchText.lowercased()) ?? false)
            }
        }
    }

    private func loadJournals() async {
        do {
            let results: [DailyJournal] = try await SupabaseService.shared.client
                .from("daily_journal")
                .select()
                .eq("device_id", value: viewModel.deviceId)
                .order("created_at", ascending: false)
                .execute()
                .value

            journals = results
        } catch {
            print("Error loading journals: \(error)")
        }
    }
}

struct JournalEntryCard: View {
    let journal: DailyJournal

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date
            Text(formatDate(journal.createdAt))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "#8B5CF6"))

            // Prompt (if exists)
            if let prompt = journal.prompt {
                Text(prompt)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "#1F2937"))
            }

            // Entry preview (first 2-3 lines)
            Text(journal.entry)
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "#6B7280"))
                .lineLimit(3)

            // Photo thumbnails
            if let photoUrls = journal.photoUrls, !photoUrls.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(photoUrls.prefix(3), id: \.self) { photoUrl in
                            AsyncImage(url: URL(string: photoUrl)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                case .failure(_), .empty:
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                        if photoUrls.count > 3 {
                            Text("+\(photoUrls.count - 3)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(hex: "#6B7280"))
                                .frame(width: 60, height: 60)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }

            // Read time
            HStack {
                Text("\(estimatedReadTime(journal.wordCount)) min read")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#9CA3AF"))

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#9CA3AF"))
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    private func estimatedReadTime(_ wordCount: Int) -> Int {
        max(1, wordCount / 200) // Average reading speed
    }
}

struct JournalDetailView: View {
    let journal: DailyJournal
    @Environment(\.dismiss) var dismiss
    @State private var showEditJournal = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Date
                    Text(formatDate(journal.createdAt))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "#8B5CF6"))

                    // Prompt
                    if let prompt = journal.prompt {
                        Text(prompt)
                            .font(.system(size: 20, weight: .semibold, design: .serif))
                            .foregroundColor(Color(hex: "#1F2937"))
                    }

                    Divider()

                    // Full entry
                    Text(journal.entry)
                        .font(.system(size: 17))
                        .foregroundColor(Color(hex: "#1F2937"))
                        .lineSpacing(6)

                    // Attached photos
                    if let photoUrls = journal.photoUrls, !photoUrls.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Photos")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(hex: "#1F2937"))

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(photoUrls, id: \.self) { photoUrl in
                                        AsyncImage(url: URL(string: photoUrl)) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 250, height: 250)
                                                    .clipped()
                                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                            case .failure(_):
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.3))
                                                    .frame(width: 250, height: 250)
                                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                                    .overlay(
                                                        Image(systemName: "photo")
                                                            .foregroundColor(.gray)
                                                    )
                                            case .empty:
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.2))
                                                    .frame(width: 250, height: 250)
                                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                                    .overlay(
                                                        ProgressView()
                                                    )
                                            @unknown default:
                                                EmptyView()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                .padding()
            }
            .background(Color(hex: "#FAF9F6"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showEditJournal = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                            Text("Edit")
                        }
                        .foregroundColor(Color(hex: "#8B5CF6"))
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showEditJournal) {
            EditJournalView(journal: journal, onSave: {
                showEditJournal = false
                dismiss()
            })
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Edit Journal View
struct EditJournalView: View {
    let journal: DailyJournal
    let onSave: () -> Void

    @State private var editedEntry: String
    @State private var editedPhotoUrls: [String]
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isUploadingPhoto = false
    @State private var showMoodPicker = false
    @State private var showColorPicker = false
    @State private var selectedColor: Color = Color(red: 0.82, green: 0.84, blue: 0.97)
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.dismiss) var dismiss

    init(journal: DailyJournal, onSave: @escaping () -> Void) {
        self.journal = journal
        self.onSave = onSave
        _editedEntry = State(initialValue: journal.entry)
        _editedPhotoUrls = State(initialValue: journal.photoUrls ?? [])
    }

    private var darkText: Color { Color(red: 0.08, green: 0.08, blue: 0.14) }
    private var mutedText: Color { Color(red: 0.42, green: 0.42, blue: 0.48) }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [selectedColor, selectedColor.opacity(0.85)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20))
                            .foregroundColor(darkText)
                            .frame(width: 44, height: 44)
                    }

                    Spacer()

                    Button(action: {
                        Task {
                            await saveJournal()
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

                if let prompt = journal.prompt {
                    Text(prompt)
                        .font(.system(size: 18, weight: .medium, design: .serif))
                        .foregroundColor(darkText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                }

                // Text editor and images
                VStack(spacing: 0) {
                    ZStack(alignment: .topLeading) {
                        if editedEntry.isEmpty {
                            Text("Start writing...")
                                .font(.system(size: 18))
                                .foregroundColor(mutedText.opacity(0.6))
                                .padding(.horizontal, 24)
                                .padding(.top, 20)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $editedEntry)
                            .font(.system(size: 18))
                            .foregroundColor(darkText)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .focused($isTextFieldFocused)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Display attached photos in horizontal scroll
                    if !editedPhotoUrls.isEmpty || isUploadingPhoto {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(editedPhotoUrls.enumerated()), id: \.offset) { index, photoUrl in
                                    ZStack(alignment: .topTrailing) {
                                        AsyncImage(url: URL(string: photoUrl)) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 200, height: 200)
                                                    .clipped()
                                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                            case .failure(_):
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.3))
                                                    .frame(width: 200, height: 200)
                                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                                    .overlay(
                                                        Image(systemName: "photo")
                                                            .foregroundColor(.gray)
                                                    )
                                            case .empty:
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.2))
                                                    .frame(width: 200, height: 200)
                                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                            @unknown default:
                                                EmptyView()
                                            }
                                        }

                                        Button(action: {
                                            Task {
                                                await removePhoto(at: index)
                                            }
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(.white)
                                                .shadow(color: .black.opacity(0.3), radius: 2)
                                        }
                                        .padding(8)
                                    }
                                }

                                // Upload indicator
                                if isUploadingPhoto {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 200, height: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .overlay(
                                            ProgressView()
                                                .scaleEffect(1.5)
                                        )
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                        }
                    }
                }

                if isTextFieldFocused { bottomToolbar }
            }
        }
        .onAppear { isTextFieldFocused = true }
    }

    // MARK: - Bottom Toolbar
    private var bottomToolbar: some View {
        HStack(spacing: 8) {
            Button(action: { showMoodPicker = true }) {
                Image(systemName: "face.smiling")
                    .font(.system(size: 20))
                    .foregroundColor(darkText)
                    .frame(width: 40, height: 40)
            }

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Image(systemName: "photo")
                    .font(.system(size: 20))
                    .foregroundColor(darkText)
                    .frame(width: 40, height: 40)
            }
            .onChange(of: selectedPhoto) { newItem in
                Task {
                    if let item = newItem {
                        await attachPhoto(item)
                        selectedPhoto = nil
                    }
                }
            }

            Button(action: { showColorPicker = true }) {
                Image(systemName: "paintpalette")
                    .font(.system(size: 20))
                    .foregroundColor(darkText)
                    .frame(width: 40, height: 40)
            }

            Menu {
                Button(action: { insertBulletPoint() }) {
                    Label("Bullet List", systemImage: "list.bullet")
                }
                Button(action: { insertNumberedPoint() }) {
                    Label("Numbered List", systemImage: "list.number")
                }
            } label: {
                Image(systemName: "list.bullet")
                    .font(.system(size: 20))
                    .foregroundColor(darkText)
                    .frame(width: 40, height: 40)
            }

            Spacer()

            Button(action: { isTextFieldFocused = false }) {
                Image(systemName: "keyboard.chevron.compact.down")
                    .font(.system(size: 20))
                    .foregroundColor(darkText)
                    .frame(width: 40, height: 40)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.5))
        .clipShape(Capsule())
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func insertBulletPoint() {
        if !editedEntry.isEmpty && !editedEntry.hasSuffix("\n") {
            editedEntry += "\n"
        }
        editedEntry += "• "
    }

    private func insertNumberedPoint() {
        if !editedEntry.isEmpty && !editedEntry.hasSuffix("\n") {
            editedEntry += "\n"
        }
        let lines = editedEntry.components(separatedBy: "\n")
        let numbered = lines.filter { $0.trimmingCharacters(in: .whitespaces).first?.isNumber == true }
        editedEntry += "\(numbered.count + 1). "
    }

    private func attachPhoto(_ item: PhotosPickerItem) async {
        isUploadingPhoto = true
        do {
            let deviceId = UserDefaults.standard.string(forKey: "hype_device_id") ?? UUID().uuidString
            let journalId = deviceId + "_" + journal.id.uuidString
            let photoUrl = try await PhotoStorageService.shared.uploadPhoto(
                item: item,
                journalId: journalId
            )
            editedPhotoUrls.append(photoUrl)
        } catch {
            print("Failed to upload photo: \(error)")
        }
        isUploadingPhoto = false
    }

    private func removePhoto(at index: Int) async {
        let url = editedPhotoUrls[index]
        do {
            try await PhotoStorageService.shared.deletePhoto(url: url)
            editedPhotoUrls.remove(at: index)
        } catch {
            print("Failed to delete photo: \(error)")
        }
    }

    private func saveJournal() async {
        guard !editedEntry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let words = editedEntry.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        let updatedJournal = DailyJournal(
            id: journal.id,
            deviceId: journal.deviceId,
            date: journal.date,
            entry: editedEntry,
            prompt: journal.prompt,
            feeling: journal.feeling,
            wordCount: words,
            photoUrls: editedPhotoUrls,
            createdAt: journal.createdAt,
            updatedAt: Date()
        )

        do {
            try await SupabaseService.shared.client
                .from("daily_journal")
                .upsert(updatedJournal)
                .execute()
        } catch {
            print("Error updating journal: \(error)")
        }
    }
}
