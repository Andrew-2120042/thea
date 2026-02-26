import SwiftUI

struct HomeTabView: View {
    @Binding var showRitualFlow: Bool
    @StateObject private var affirmationVM = AffirmationViewModel()
    @StateObject private var intentionsVM = IntentionsViewModel()

    @State private var currentStreak = 0
    @State private var userName = "Celeste"

    var body: some View {
        ZStack {
            // Time-based gradient background
            timeBasedGradient
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Greeting
                VStack(spacing: 8) {
                    Text(timeBasedGreeting)
                        .font(.system(size: 48, weight: .regular, design: .serif))
                        .foregroundColor(.white)

                    Text(userName)
                        .font(.system(size: 48, weight: .regular, design: .serif))
                        .foregroundColor(.white)
                }

                // Streak badge
                HStack(spacing: 8) {
                    Text("🔥")
                        .font(.system(size: 24))

                    Text("\(currentStreak) day streak")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
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
        }
        .onAppear {
            loadData()
        }
    }

    private var timeBasedGradient: some View {
        let hour = Calendar.current.component(.hour, from: Date())

        let colors: [Color] = {
            switch hour {
            case 5..<12:  // Morning
                return [Color(hex: "#FDB99B"), Color(hex: "#FCA15D"), Color(hex: "#F9845B")]
            case 12..<17: // Afternoon
                return [Color(hex: "#FFE5B4"), Color(hex: "#FFDAB9"), Color(hex: "#FFB6C1")]
            case 17..<21: // Evening
                return [Color(hex: "#E0BBE4"), Color(hex: "#C8A2C8"), Color(hex: "#B19CD9")]
            default:      // Night
                return [Color(hex: "#2C3E50"), Color(hex: "#3D5A80"), Color(hex: "#4A6FA5")]
            }
        }()

        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var timeBasedGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
    }

    private var todaysFocusPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Focus:")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            VStack(alignment: .leading, spacing: 8) {
                ForEach(intentionsVM.intentions.prefix(3)) { intention in
                    HStack(spacing: 8) {
                        Image(systemName: intention.completed ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.system(size: 14))

                        Text(intention.text)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
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
            // Load streak
            currentStreak = UserDefaults.standard.integer(forKey: "currentStreak")
            if currentStreak == 0 {
                currentStreak = 1
            }

            // Load user name
            if let name = UserDefaults.standard.string(forKey: "userName") {
                userName = name
            }

            // Load today's intentions
            await intentionsVM.loadToday()
        }
    }
}
