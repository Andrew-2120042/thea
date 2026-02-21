# HYPE App - Project Structure & Documentation

## Project Structure

This project has a unique dual-directory structure:

### Root Directories (Compiled by Xcode)
```
/App/              - App entry point and delegates
/Config/           - Constants and configuration
/Models/           - Data models (Codable structs)
/Services/         - Business logic and API services
/Utilities/        - Helper functions and extensions
/ViewModels/       - Observable view models (@MainActor)
/Views/            - SwiftUI views
  /Components/     - Reusable UI components
  /Main/           - Main app screens
  /Onboarding/     - Onboarding flow screens
```

### HypeApp/ Directory (Backup/Working Copy)
- Identical structure to root directories
- Acts as a working copy and backup
- Changes should be synced between both locations

## Key Features Implemented

### 1. Insights Page (`InsightsContainerView`)
- **Location**: `Views/Main/InsightsContainerView.swift`
- **Features**:
  - Bottom navigation bar with Home button (gradient) + Stats/Today/Journal pill
  - Tab-based navigation between different sections
  - Automatic data loading on appear

### 2. Stats Tab (`StatsTabView`)
- **Location**: `Views/Main/StatsTabView.swift`
- **Features**:
  - Current streak and longest streak tracking
  - Weekly activity stats (affirmations, intentions, journals)
  - Calendar view with completion data
  - Mood tracking and visualization

### 3. Today's Intentions (`TodaysIntentionsView`)
- **Location**: `Views/Main/TodaysIntentionsView.swift`
- **Features**:
  - Weekly calendar header with date selection
  - Month selector with picker
  - Disable future dates (only today/past selectable)
  - Add, view, complete, and delete intentions
  - Auto-save on add/toggle completion

### 4. Journal History (`JournalHistoryView`)
- **Location**: `Views/Main/JournalHistoryView.swift`
- **Features**:
  - Search functionality for journals
  - Journal entry cards with date, prompt, preview
  - Photo thumbnails (max 3 visible + count)
  - Read time estimation
  - Full journal detail view with all photos
  - Edit journal with full toolbar

### 5. Full-Screen Journal (`FullScreenJournalView`)
- **Location**: `Views/Main/FullScreenJournalView.swift`
- **Features**:
  - Voice recording with speech-to-text
  - Mood picker (5 moods)
  - Color theme picker (6 themes)
  - Photo attachments (multiple photos)
  - Bullet and numbered list formatting
  - Prompt rotation and custom prompts
  - Auto-save on completion

### 6. Photo Storage (`PhotoStorageService`)
- **Location**: `Services/PhotoStorageService.swift`
- **Features**:
  - Upload photos to Supabase Storage
  - Generate unique filenames (journalId + UUID)
  - Get public URLs for photos
  - Delete photos from storage
  - Error handling

## Data Models

### DailyJournal
```swift
struct DailyJournal: Codable, Identifiable {
    let id: UUID
    let deviceId: String
    let date: String          // "YYYY-MM-DD"
    var entry: String
    let prompt: String?
    let feeling: String?
    let wordCount: Int
    var photoUrls: [String]?  // Array of Supabase Storage URLs
    let createdAt: Date
    let updatedAt: Date
}
```

**Special Note**: Includes custom `encode(to:)` method to skip `photoUrls` when nil, preventing errors when the `photo_urls` column doesn't exist in Supabase.

### DailyIntentions
```swift
struct DailyIntentions: Codable, Identifiable {
    let id: UUID
    let deviceId: String
    let date: String
    var intentions: [Intention]
    let feeling: String?
    let createdAt: Date
    let updatedAt: Date
}
```

### Intention
```swift
struct Intention: Codable, Identifiable {
    let id: String           // UUID string
    var text: String
    var completed: Bool
    var completedAt: Date?
    let createdAt: Date
}
```

## Services

### JournalService
- `getTodaysJournal()` - Fetch today's journal entry
- `saveJournal(entry:prompt:feeling:photoUrls:)` - Save/update journal with optional photos
- Uses device-based authentication with `hype_device_id`

### IntentionsService
- `getTodaysIntentions()` - Fetch today's intentions
- `saveIntentions(intentions:feeling:)` - Save new daily intentions
- `updateIntentions(_:)` - Update existing intentions
- Device-based authentication

### PhotoStorageService
- `uploadPhoto(item:journalId:)` - Upload photo to Supabase Storage
- `deletePhoto(url:)` - Delete photo from storage
- Stores photos in `journals` bucket under `journal_photos/` path

## ViewModels

### JournalViewModel
- `@Published var entry: String` - Journal text
- `@Published var currentPrompt: String` - Current writing prompt
- `@Published var attachedPhotos: [String]` - Photo URLs
- `@Published var isUploadingPhoto: Bool` - Upload state
- `deviceId` - Computed property from UserDefaults
- `load(feeling:)` - Load today's journal
- `save(feeling:)` - Save journal with photos
- `attachPhoto(_:)` - Upload and attach photo
- `removePhoto(at:)` - Delete photo

### IntentionsViewModel
- `@Published var intentions: [Intention]` - Current intentions
- `@Published var isLoading: Bool` - Loading state
- `deviceId` - Computed property from UserDefaults
- `loadToday()` - Load today's intentions
- `addIntention(text:)` - Add new intention
- `save(feeling:)` - Save intentions to Supabase
- `toggleCompletion(id:)` - Toggle and persist completion

### StatsViewModel
- `@Published` properties for all stats (streaks, counts, calendar data, etc.)
- `deviceId` - Computed property from UserDefaults
- `loadStats()` - Load all statistics
- `calculateStreak()` - Calculate current and longest streaks

## Important Implementation Details

### Device ID Management
All ViewModels use a **computed property** for `deviceId`:
```swift
var deviceId: String {
    let key = "hype_device_id"
    if let stored = UserDefaults.standard.string(forKey: key) { return stored }
    let new = UUID().uuidString
    UserDefaults.standard.set(new, forKey: key)
    return new
}
```

This ensures:
- Consistent device identification across app sessions
- No need for external assignment
- Automatic creation on first access

### Supabase Table Structure

#### daily_journal
- `id` (UUID, primary key)
- `device_id` (TEXT)
- `date` (TEXT) - Format: "YYYY-MM-DD"
- `entry` (TEXT)
- `prompt` (TEXT, nullable)
- `feeling` (TEXT, nullable)
- `word_count` (INTEGER)
- `photo_urls` (TEXT[], nullable) - **Add this column if using photo attachments**
- `created_at` (TIMESTAMPTZ)
- `updated_at` (TIMESTAMPTZ)

#### daily_intentions
- `id` (UUID, primary key)
- `device_id` (TEXT)
- `date` (TEXT) - Format: "YYYY-MM-DD"
- `intentions` (JSONB) - Array of Intention objects
- `feeling` (TEXT, nullable)
- `created_at` (TIMESTAMPTZ)
- `updated_at` (TIMESTAMPTZ)

### Supabase Storage Setup

Create a storage bucket named `journals` (public access) for photo storage.

## Navigation Flow

### Morning Flow
1. Home → Check In
2. Ritual (Affirmation)
3. Thanks screen
4. Feeling selector
5. **Intentions Input** (page 6)
6. Finish → Back to Home

### Night Flow
1. Home → Check In
2. Ritual (Affirmation)
3. Thanks screen
4. Feeling selector
5. **Journal Entry** (page 9)
6. Finish → Back to Home

### Insights Access
- Tap "Insights" pill on Home screen
- Opens `InsightsContainerView` in full-screen cover
- Navigate between Stats/Today/Journal tabs
- Tap Home button to return

## File Sync Workflow

To sync changes between root and HypeApp:

```bash
# Sync from root to HypeApp (backup)
rsync -av --update Services/ HypeApp/Services/
rsync -av --update Models/ HypeApp/Models/
rsync -av --update ViewModels/ HypeApp/ViewModels/
rsync -av --update Views/Main/ HypeApp/Views/Main/

# Or sync from HypeApp to root (restore)
rsync -av --update HypeApp/Services/ Services/
rsync -av --update HypeApp/Models/ Models/
rsync -av --update HypeApp/ViewModels/ ViewModels/
rsync -av --update HypeApp/Views/Main/ Views/Main/
```

## Build & Run

```bash
# Clean build
xcodebuild -scheme HypeApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' clean build

# Run in Xcode
# Cmd+B to build
# Cmd+R to run
```

## Recent Commits

- **0370705**: Add Insights page, photo attachments, calendar header, and UI improvements
- **5266ce3**: Add voice recording to journal with speech-to-text
- **e4c0984**: Add morning intentions + night journaling features

## Known Issues & Solutions

### Issue: Journal Not Saving
**Cause**: `photo_urls` column doesn't exist in Supabase
**Solution**: Custom encoder in DailyJournal skips nil photoUrls

### Issue: Previous Data Not Loading
**Cause**: Empty deviceId in ViewModels
**Solution**: ViewModels now have computed deviceId from UserDefaults

### Issue: Compiler Errors with Property Access
**Cause**: @StateObject property access issues in async contexts
**Solution**: Use computed properties instead of stored properties + setters

## Future Enhancements

1. Add `photo_urls` column to Supabase `daily_journal` table
2. Implement photo editing (crop, filters)
3. Add journal export functionality
4. Implement journal sharing
5. Add analytics and insights based on journal sentiment
6. Cloud sync across devices (requires user authentication)
