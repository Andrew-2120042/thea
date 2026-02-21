import SwiftUI

struct InsightsContainerView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab: InsightsTab = .stats
    @StateObject private var statsVM = StatsViewModel()
    @StateObject private var intentionsVM = IntentionsViewModel()
    @StateObject private var journalVM = JournalViewModel()

    enum InsightsTab: String, CaseIterable {
        case home = "Home"
        case stats = "Stats"
        case today = "Today"
        case journal = "Journal"

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .stats: return "chart.bar.fill"
            case .today: return "checkmark.circle.fill"
            case .journal: return "book.fill"
            }
        }
    }

    var body: some View {
        ZStack {
            // Background
            Color(hex: "#FAF9F6")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Main content area
                ZStack {
                    switch selectedTab {
                    case .home:
                        // This just dismisses back to home
                        Color.clear
                            .onAppear {
                                dismiss()
                            }

                    case .stats:
                        StatsTabView(viewModel: statsVM)

                    case .today:
                        TodaysIntentionsView(
                            viewModel: intentionsVM,
                            todaysAffirmation: nil,
                            onDone: {
                                dismiss()
                            }
                        )

                    case .journal:
                        JournalHistoryView(viewModel: journalVM)
                    }
                }

                // Bottom navigation
                bottomNavBar
            }
        }
        .onAppear {
            Task {
                await intentionsVM.loadToday()
                await statsVM.loadStats()
            }
        }
    }

    private var bottomNavBar: some View {
        HStack(spacing: 12) {
            // Home button - separate with gradient
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = .home
                }
            }) {
                VStack(spacing: 4) {
                    Image(systemName: InsightsTab.home.icon)
                        .font(.system(size: 22))
                        .foregroundColor(.white)

                    Text(InsightsTab.home.rawValue)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                }
                .frame(width: 80)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#8B5CF6"), Color(hex: "#7C3AED")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color(hex: "#8B5CF6").opacity(0.3), radius: 8, y: 4)
            }

            // Other tabs in pill
            HStack(spacing: 0) {
                ForEach([InsightsTab.stats, InsightsTab.today, InsightsTab.journal], id: \.self) { tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 22))
                                .foregroundColor(selectedTab == tab ? Color(hex: "#8B5CF6") : Color(hex: "#9CA3AF"))

                            Text(tab.rawValue)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(selectedTab == tab ? Color(hex: "#8B5CF6") : Color(hex: "#9CA3AF"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                }
            }
            .background(Color.white)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.08), radius: 12, y: 4)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
}
