import SwiftUI

struct AffirmationsFeedView: View {
    @StateObject private var affirmationVM = AffirmationViewModel()

    @State private var currentIndex: Int? = 0
    @State private var showFilters = false
    @State private var selectedCategory: String = "All"
    @State private var selectedMode: String = "All"

    private let categories = ["All", "Confidence", "Self-Care", "Boundaries", "Abundance", "Healing", "Gratitude", "Relationships", "Career"]
    private let modes = ["All", "Morning", "Night"]

    var body: some View {
        ZStack {
            if !filteredAffirmations.isEmpty {
                AffirmationsReelView(affirmations: filteredAffirmations, currentIndex: $currentIndex)

                // Fixed header overlay
                VStack {
                    HStack {
                        Text("Affirmations")
                            .font(.system(size: 32, weight: .regular, design: .serif))
                            .foregroundColor(Color(hex: "#1A1A1A"))

                        Spacer()

                        Button(action: { showFilters.toggle() }) {
                            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(Color(hex: "#8B5CF6"))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 60)

                    Spacer()
                }

            } else if affirmationVM.isLoading {
                Color(hex: "#FAF9F6")
                    .ignoresSafeArea()

                ProgressView()
                    .scaleEffect(1.5)
                    .tint(Color(hex: "#8B5CF6"))
            } else {
                Color(hex: "#FAF9F6")
                    .ignoresSafeArea()

                VStack(spacing: 8) {
                    Text("No affirmations found")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(hex: "#6B7280"))
                    Text("Try changing your filters")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#9CA3AF"))
                }
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showFilters) {
            ReelFiltersSheet(
                selectedCategory: $selectedCategory,
                selectedMode: $selectedMode,
                categories: categories,
                modes: modes
            )
            .presentationDetents([.height(400)])
        }
        .onAppear {
            Task { await affirmationVM.loadAllAffirmations() }
        }
        .onChange(of: selectedCategory) {
            currentIndex = 0
        }
        .onChange(of: selectedMode) {
            currentIndex = 0
        }
    }

    private var filteredAffirmations: [Affirmation] {
        affirmationVM.allAffirmations.filter { a in
            var ok = true
            if selectedCategory != "All" {
                ok = ok && a.category.lowercased() == selectedCategory.lowercased()
            }
            if selectedMode != "All" {
                ok = ok && a.mode.rawValue.lowercased() == selectedMode.lowercased()
            }
            return ok
        }
    }
}

// MARK: - Reel Container

struct AffirmationsReelView: View {
    let affirmations: [Affirmation]
    @Binding var currentIndex: Int?

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(Array(affirmations.enumerated()), id: \.element.id) { index, affirmation in
                    AffirmationCard(affirmation: affirmation)
                        .containerRelativeFrame([.horizontal, .vertical])
                        .id(index)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .ignoresSafeArea()
        .scrollPosition(id: $currentIndex)
    }
}

// MARK: - Card

struct AffirmationCard: View {
    let affirmation: Affirmation
    @State private var isFavorited = false

    var body: some View {
        ZStack {
            // Background — renders edge-to-edge
            Color(hex: "#FAF9F6")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 120)

                Spacer()

                // Mode badge
                HStack(spacing: 6) {
                    Image(systemName: affirmation.mode == .morning ? "sunrise.fill" : "moon.stars.fill")
                        .font(.system(size: 13))
                        .foregroundColor(affirmation.mode == .morning ? .orange : Color(hex: "#8B5CF6"))

                    Text(affirmation.mode.rawValue.capitalized)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "#6B7280"))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.white)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
                .padding(.bottom, 28)

                // Affirmation text
                Text(affirmation.text)
                    .font(.system(size: 32, weight: .regular, design: .serif))
                    .foregroundColor(Color(hex: "#1A1A1A"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .padding(.horizontal, 36)

                // Category
                Text(affirmation.category.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "#8B5CF6"))
                    .tracking(1.5)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#8B5CF6").opacity(0.1))
                    .clipShape(Capsule())
                    .padding(.top, 24)

                Spacer()

                // Action buttons
                HStack(spacing: 40) {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isFavorited.toggle()
                            HapticManager.impact(.light)
                        }
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: isFavorited ? "heart.fill" : "heart")
                                .font(.system(size: 24))
                                .foregroundColor(isFavorited ? Color(hex: "#EC4899") : Color(hex: "#9CA3AF"))
                                .scaleEffect(isFavorited ? 1.15 : 1.0)

                            Text(isFavorited ? "Saved" : "Save")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color(hex: "#9CA3AF"))
                        }
                    }

                    Button(action: { shareAffirmation() }) {
                        VStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 24))
                                .foregroundColor(Color(hex: "#9CA3AF"))

                            Text("Share")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color(hex: "#9CA3AF"))
                        }
                    }
                }
                .padding(.bottom, 100)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func shareAffirmation() {
        let text = "\"\(affirmation.text)\" — HYPE"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(activityVC, animated: true)
        }
    }
}

// MARK: - Filters Sheet

struct ReelFiltersSheet: View {
    @Binding var selectedCategory: String
    @Binding var selectedMode: String
    let categories: [String]
    let modes: [String]

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#FAF9F6")
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Category")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(hex: "#1F2937"))
                            .padding(.horizontal, 20)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(categories, id: \.self) { category in
                                    ReelFilterChip(
                                        title: category,
                                        isSelected: selectedCategory == category,
                                        action: { selectedCategory = category }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    Divider().padding(.horizontal, 20)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Time of Day")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(hex: "#1F2937"))
                            .padding(.horizontal, 20)

                        HStack(spacing: 8) {
                            ForEach(modes, id: \.self) { mode in
                                ReelFilterChip(
                                    title: mode,
                                    isSelected: selectedMode == mode,
                                    action: { selectedMode = mode }
                                )
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                    }

                    Spacer()

                    Button(action: { dismiss() }) {
                        Text("Apply Filters")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "#8B5CF6"))
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .padding(.top, 20)
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct ReelFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : Color(hex: "#6B7280"))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color(hex: "#8B5CF6") : Color(hex: "#F3F4F6"))
                .cornerRadius(20)
        }
    }
}
