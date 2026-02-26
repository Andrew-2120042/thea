import SwiftUI

// Accent used throughout settings — warm rose/terracotta, no purple
private let settingsAccent = HypeSettingsColors.accent
private let settingsBg     = HypeSettingsColors.bg
private let settingsDark   = HypeSettingsColors.dark
private let settingsMuted  = HypeSettingsColors.muted

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @AppStorage("onboardingCompleted") private var onboardingCompleted = true
    @EnvironmentObject var storeKit: StoreKitService
    @State private var showPaywall    = false
    @State private var showDeleteAlert = false

    var body: some View {
        ZStack {
            settingsBg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

                    // Header
                    HStack {
                        Text("Settings")
                            .font(.system(size: 34, weight: .regular, design: .serif))
                            .foregroundColor(settingsDark)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 70)

                    // Profile card
                    settingsCard {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(settingsAccent.opacity(0.15))
                                    .frame(width: 52, height: 52)
                                Text(viewModel.settings.name.prefix(1).uppercased())
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(settingsAccent)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                TextField("Your name", text: $viewModel.settings.name)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(settingsDark)

                                if storeKit.isPremium {
                                    Label("HYPE Premium", systemImage: "crown.fill")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(settingsAccent)
                                } else {
                                    Button("Upgrade to Premium") { showPaywall = true }
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(settingsAccent)
                                }
                            }
                            Spacer()
                        }
                        .padding(20)
                    }

                    // Notifications card
                    settingsCard {
                        VStack(spacing: 0) {
                            cardHeader(title: "Notifications", icon: "bell.fill")
                            Divider().padding(.horizontal, 20)
                            ToggleCard(
                                icon: "🌅", title: "Morning",
                                subtitle: "Daily morning affirmation",
                                isOn: $viewModel.settings.morningEnabled,
                                time: $viewModel.morningTime,
                                textColor: settingsDark
                            )
                            Divider().padding(.horizontal, 20)
                            ToggleCard(
                                icon: "🌙", title: "Night",
                                subtitle: "Evening reflection",
                                isOn: $viewModel.settings.nightEnabled,
                                time: $viewModel.nightTime,
                                textColor: settingsDark
                            )
                        }
                    }

                    // Voice card
                    settingsCard {
                        VStack(spacing: 14) {
                            cardHeader(title: "Voice", icon: "waveform")
                            Divider()
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Voice threshold")
                                        .font(.system(size: 15))
                                        .foregroundColor(settingsDark)
                                    Spacer()
                                    Text("\(Int(viewModel.settings.voiceThreshold))%")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(settingsAccent)
                                }
                                HStack {
                                    Text("Quiet")
                                        .font(.caption).foregroundColor(settingsMuted)
                                    Slider(value: $viewModel.settings.voiceThreshold,
                                           in: 30...90, step: 5)
                                        .tint(settingsAccent)
                                    Text("Loud")
                                        .font(.caption).foregroundColor(settingsMuted)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 4)
                        }
                    }

                    // Preferences card
                    settingsCard {
                        VStack(spacing: 0) {
                            cardHeader(title: "Preferences", icon: "slider.horizontal.3")
                            Divider().padding(.horizontal, 20)
                            lightRow(icon: "🏷️", title: "Categories") {}
                        }
                    }

                    // About card
                    settingsCard {
                        VStack(spacing: 0) {
                            cardHeader(title: "About", icon: "info.circle")
                            Divider().padding(.horizontal, 20)
                            lightRow(icon: "⭐", title: "Rate HYPE") {}
                            Divider().padding(.horizontal, 20)
                            lightRow(icon: "🔒", title: "Privacy Policy") {}
                            Divider().padding(.horizontal, 20)
                            lightRow(icon: "📜", title: "Terms of Service") {}
                            Divider().padding(.horizontal, 20)
                            lightRow(icon: "🔄", title: "Restore Purchases") {
                                Task { await storeKit.restorePurchases() }
                            }
                        }
                    }

                    // Save button
                    Button(action: { viewModel.saveSettings() }) {
                        Text("Save Settings")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 72)
                            .background(settingsDark)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 24)

                    Button(action: { showDeleteAlert = true }) {
                        Text("Delete all data")
                            .font(.system(size: 14))
                            .foregroundColor(.red.opacity(0.6))
                    }
                    .padding(.bottom, 60)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear { viewModel.loadSettings() }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView()
        }
        .alert("Delete All Data", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                viewModel.deleteAllData()
                onboardingCompleted = false
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete all your streaks and settings. This cannot be undone.")
        }
    }

    // MARK: - Card builder
    @ViewBuilder
    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
            .padding(.horizontal, 24)
    }

    // MARK: - Card header
    @ViewBuilder
    private func cardHeader(title: String, icon: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(settingsMuted)
                .textCase(.uppercase)
                .tracking(1)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - Light row
    @ViewBuilder
    private func lightRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(icon).font(.system(size: 20)).frame(width: 32)
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(settingsDark)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundColor(settingsMuted.opacity(0.6))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Settings Section Header (kept for any external references)
struct SettingsSectionHeader: View {
    let title: String
    let icon: String
    var body: some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(settingsMuted)
                .textCase(.uppercase)
                .tracking(1)
            Spacer()
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Settings Row (kept for any external references)
struct SettingsRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(icon).font(.system(size: 20)).frame(width: 32)
                Text(title).font(.system(size: 16)).foregroundColor(settingsDark)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13)).foregroundColor(settingsMuted)
            }
            .padding(.vertical, 14)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
