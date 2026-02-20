# HYPE App — Setup Guide

## Quick Start

### 1. Create Xcode Project

1. Open Xcode → File → New → Project
2. Choose **App** template
3. Settings:
   - Product Name: `HypeApp`
   - Bundle ID: `com.yourcompany.HypeApp`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Minimum Deployment: **iOS 16.0**

### 2. Add Source Files to Xcode

Drag the entire `HypeApp/` folder into your Xcode project navigator. When prompted:
- ✅ Copy items if needed
- ✅ Create groups
- ✅ Add to target: HypeApp

### 3. Install Swift Packages

In Xcode: **File → Add Package Dependencies**

| Package | URL | Version |
|---------|-----|---------|
| Supabase Swift | `https://github.com/supabase/supabase-swift` | `2.0.0+` |

### 4. Configure Supabase

1. Create project at [supabase.com](https://supabase.com)
2. Run `Resources/schema.sql` in the **SQL Editor**
3. Copy your Project URL and anon key
4. Update `Config/Constants.swift`:

```swift
static let supabaseURL = "https://YOUR_PROJECT.supabase.co"
static let supabaseAnonKey = "YOUR_ANON_KEY"
```

### 5. Configure App Store Connect (In-App Purchases)

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Create new app with your Bundle ID
3. Add subscriptions:
   - `com.yourcompany.HypeApp.monthly` — $4.99/month
   - `com.yourcompany.HypeApp.yearly` — $29.99/year
4. Update `Config/Constants.swift` with your actual product IDs

### 6. Info.plist Permissions

Add these keys in Xcode → Target → Info:

| Key | Value |
|-----|-------|
| NSMicrophoneUsageDescription | "HYPE needs microphone access to verify you're speaking affirmations out loud" |
| NSUserNotificationsUsageDescription | "HYPE sends daily reminders for your affirmations" |

### 7. Build & Run

```
Cmd+B  →  Build
Cmd+R  →  Run on Simulator
```

---

## Architecture

```
MVVM + SwiftUI

App Entry
└── HypeApp.swift (@main)
    ├── OnboardingContainerView (first launch)
    └── MainContainerView (after onboarding)
        ├── HomeView
        ├── CalendarView
        └── SettingsView

Services (singleton)
├── SupabaseService    — API client
├── AffirmationService — content + fallbacks
├── VoiceService       — AVFoundation recording
├── StoreKitService    — in-app purchases (StoreKit 2)
├── NotificationService — UNUserNotificationCenter
└── StreakService       — streak logic

Storage
├── UserDefaults — UserSettings (local, persisted)
└── Supabase     — user_activity (remote)
```

## Key Features

| Feature | Implementation |
|---------|----------------|
| Glass morphism | `.ultraThinMaterial` |
| Voice detection | `AVAudioRecorder` metering |
| Circular voice UI | `CircularVoiceDetector.swift` |
| Streaks | `StreakService.swift` |
| IAP | StoreKit 2 (no RevenueCat) |
| Notifications | `UserNotifications` framework |
| Confetti | Pure SwiftUI particle system |
| Supabase | `supabase-swift` package |

## Free Tier

- **7 free affirmations** before paywall
- Tracked via `UserSettings.freeAffirmationsUsed`
- Paywall: $4.99/month or $29.99/year
