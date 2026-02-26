import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: AppTab = .home
    @State private var showRitualFlow = false

    enum AppTab: String, CaseIterable {
        case home = "Home"
        case affirmations = "Affirmations"
        case journal = "Journal"
        case focus = "Focus"
        case profile = "Profile"

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .affirmations: return "sparkles"
            case .journal: return "book.fill"
            case .focus: return "checkmark.circle.fill"
            case .profile: return "person.crop.circle.fill"
            }
        }
    }

    var body: some View {
        ZStack {
            // Main tab content
            TabView(selection: $selectedTab) {
                // Tab 1: Home
                HomeTabView(showRitualFlow: $showRitualFlow)
                    .tag(AppTab.home)
                    .tabItem {
                        Label(AppTab.home.rawValue, systemImage: AppTab.home.icon)
                    }

                // Tab 2: Affirmations Feed
                AffirmationsFeedView()
                    .tag(AppTab.affirmations)
                    .tabItem {
                        Label(AppTab.affirmations.rawValue, systemImage: AppTab.affirmations.icon)
                    }

                // Tab 3: Journal
                JournalHistoryView(viewModel: JournalViewModel())
                    .tag(AppTab.journal)
                    .tabItem {
                        Label(AppTab.journal.rawValue, systemImage: AppTab.journal.icon)
                    }

                // Tab 4: Focus (Today's Intentions)
                TodaysIntentionsView(
                    viewModel: IntentionsViewModel(),
                    todaysAffirmation: nil,
                    onDone: {}
                )
                .tag(AppTab.focus)
                .tabItem {
                    Label(AppTab.focus.rawValue, systemImage: AppTab.focus.icon)
                }

                // Tab 5: Profile/Settings
                ProfileView()
                    .tag(AppTab.profile)
                    .tabItem {
                        Label(AppTab.profile.rawValue, systemImage: AppTab.profile.icon)
                    }
            }
            .accentColor(Color(hex: "#8B5CF6"))
        }
        .fullScreenCover(isPresented: $showRitualFlow) {
            RitualFlowView(isPresented: $showRitualFlow)
        }
    }
}
