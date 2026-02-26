import SwiftUI

struct HomeTabView: View {
    @Binding var showRitualFlow: Bool
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var affirmationVM = AffirmationViewModel()
    @StateObject private var intentionsVM = IntentionsViewModel()

    @State private var currentStreak = 0
    @State private var userName = "Celeste"

    var body: some View {
        ZStack {
            // Theme-based gradient background
            LinearGradient(
                colors: HypeColors.gradient(for: themeManager.activeTheme),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Greeting
                VStack(spacing: 8) {
                    Text(themeManager.activeTheme.greeting)
                        .font(.system(size: 48, weight: .regular, design: .serif))
                        .foregroundColor(HypeColors.textColor(for: themeManager.activeTheme))

                    Text(userName)
                        .font(.system(size: 48, weight: .regular, design: .serif))
                        .foregroundColor(HypeColors.textColor(for: themeManager.activeTheme))
                }

                // Streak badge
                HStack(spacing: 8) {
                    Text("🔥")
                        .font(.system(size: 24))

                    Text("\(currentStreak) day streak")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(HypeColors.textColor(for: themeManager.activeTheme).opacity(0.9))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.2))
                .cornerRadius(24)

                Spacer()

                // Today's Focus Preview (if intentions exist)
                if !intentionsVM.intentions.isEmpty {
                    todaysFocusPreview
                }

                Spacer()

                // Check In button
                Button(action: {
                    showRitualFlow = true
                }) {
                    Text("Check in")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(16)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 100) // Space for tab bar
            }

            // Moon/Sun theme toggle — top-right corner
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            themeManager.toggleManualOverride()
                        }
                    }) {
                        Image(systemName: themeManager.isManualOverride ? "sun.max.fill" : "moon.fill")
                            .font(.system(size: 20))
                            .foregroundColor(HypeColors.textColor(for: themeManager.activeTheme).opacity(0.75))
                            .frame(width: 44, height: 44)
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 60)
                }
                Spacer()
            }
        }
        .onAppear {
            loadData()
        }
    }

    private var todaysFocusPreview: some View {
        let text = HypeColors.textColor(for: themeManager.activeTheme)
        return VStack(alignment: .leading, spacing: 12) {
            Text("Today's Focus:")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(text.opacity(0.9))

            VStack(alignment: .leading, spacing: 8) {
                ForEach(intentionsVM.intentions.prefix(3)) { intention in
                    HStack(spacing: 8) {
                        Image(systemName: intention.completed ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(text.opacity(0.7))
                            .font(.system(size: 14))

                        Text(intention.text)
                            .font(.system(size: 14))
                            .foregroundColor(text.opacity(0.9))
                            .strikethrough(intention.completed)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.2))
        .cornerRadius(16)
        .padding(.horizontal, 32)
    }

    private func loadData() {
        Task {
            currentStreak = UserDefaults.standard.integer(forKey: "currentStreak")
            if currentStreak == 0 { currentStreak = 1 }

            if let name = UserDefaults.standard.string(forKey: "userName") {
                userName = name
            }

            await intentionsVM.loadToday()
        }
    }
}
