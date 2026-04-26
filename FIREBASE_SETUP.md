# Clera Firebase Integration

## Overview

Clera now supports Firebase for authentication, cloud data sync, and crash reporting. All Firebase code lives in the `Infrastructure` layer and is guarded by compile-time (`#if canImport`) and runtime (`FirebaseConfiguration.isConfigured`) checks. The app builds and runs without Firebase if the configuration file is missing.

## Project Structure

```
App/Sources/Infrastructure/
  Protocols/
    AuthProviding.swift          // Auth abstraction
    CloudSyncing.swift           // Sync orchestration abstraction
    UserProfileRepository.swift  // Profile repository abstraction
    SkinScanRepository.swift     // Scan repository abstraction
    RoutineRepository.swift      // Routine repository abstraction
    CrashReporting.swift         // Crash reporter abstraction
  Errors/
    AuthError.swift              // Typed auth errors with user messages
    CloudSyncError.swift         // Typed sync errors with user messages
    FirestoreDecodingError.swift // Firestore-specific decoding errors
    MigrationError.swift         // Local-to-cloud migration errors
    CrashReportingError.swift    // Crash reporter errors
  DTOs/
    FirestoreDTOs.swift          // Codable DTOs + domain mappings
  Firebase/
    FirebaseConfiguration.swift  // Safe FirebaseApp.configure()
    FirebaseAuthService.swift    // Firebase Auth implementation
    FirestoreUserProfileRepository.swift
    FirestoreSkinScanRepository.swift
    FirestoreRoutineRepository.swift
    CloudSyncService.swift       // Bidirectional sync engine
  Migration/
    LocalToCloudMigration.swift  // One-time local data upload
  CrashReporting/
    CrashlyticsReporter.swift    // Firebase Crashlytics implementation
```

## Setup Steps

### 1. Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project (or add Clera to an existing one)
3. Add an iOS app with bundle ID: `com.attm.clera`
4. Download `GoogleService-Info.plist`
5. Place it in: `App/Resources/GoogleService-Info.plist`

### 2. Enable Firebase Services

In Firebase Console, enable:
- **Authentication** → Sign-in methods:
  - Anonymous (enable for frictionless onboarding)
  - Email/Password (enable for account creation)
- **Firestore Database** → Create database (start in test mode, then deploy rules)
- **Crashlytics** (enabled automatically when Analytics is on)

### 3. Deploy Security Rules

```bash
firebase deploy --only firestore:rules
```

Or paste the contents of `App/Resources/firebase.rules` into the Firestore Rules tab in Firebase Console.

### 4. Build

```bash
xcodegen generate
open Clera.xcodeproj
```

Xcode will resolve Swift Package Manager dependencies on first build.

### 5. Run

The app will:
1. Detect `GoogleService-Info.plist` at launch
2. Configure Firebase automatically
3. Sign the user in anonymously (first launch)
4. Begin syncing data after onboarding

## Firestore Data Model

```
users/{userId}
  /profile/main              → FirestoreUserProfileDTO
  /skinScans/{scanId}        → FirestoreScanSessionDTO
  /skinMapSnapshots/{id}     → FirestoreSkinMapSnapshotDTO
  /routineLogs/{logId}       → FirestoreRoutineLogDTO
  /routineChanges/{changeId} → FirestoreRoutineChangeDTO
  /currentProducts/{id}      → FirestoreProductDTO
  /experiments/{id}          → FirestoreExperimentDTO
  /dailyAdvice/{id}          → FirestoreDailyAdviceDTO
  /deviceState/{deviceId}    → FirestoreSyncMetadataDTO
```

**Images are NOT stored in Firestore.** Only metadata and analysis outputs sync. Images remain local on device.

## Auth Flow

1. **App Launch** → `FirebaseAuthService` listens for auth state changes
2. **No existing user** → Auto sign-in anonymously (seamless)
3. **Onboarding** → User enters name/email/password
4. **Sign Up** → Anonymous account is linked to email/password credential
5. **Log In** → Existing email/password user signed in
6. **Log Out** → Auth state changes to `.unauthenticated`

## Cloud Sync Flow

1. **After auth** → `LocalToCloudMigration` checks if local data needs uploading
2. **After scan** → `CloudSyncService.uploadScan()` pushes metadata
3. **After routine log** → `CloudSyncService.uploadRoutineLog()` pushes entry
4. **After profile update** → `CloudSyncService.uploadProfile()` pushes changes
5. **Conflict resolution** → `updatedAt` timestamp wins; local data is never deleted

## Crashlytics

Custom keys set automatically:
- `auth_state` — anonymous | authenticated | unauthenticated
- `app_version` — set from bundle info
- `build_number` — set from bundle info
- `last_sync_status` — success | failed

Non-fatal errors reported from:
- Auth failures
- Scan pipeline errors
- Cloud sync failures
- Persistence errors
- Daily advice generation errors

## Local Development Without Firebase

If `GoogleService-Info.plist` is missing:
- Firebase is silently skipped
- `NoOpCrashReporter` is used
- Auth falls back to local-only (the old behavior)
- All data stays local
- App works fully offline

To test with Firebase locally:
```bash
firebase emulators:start --only firestore,auth
```

Set `FirebaseFirestore.Settings.host` to the emulator in debug builds if needed.

## Testing

Tests use mock implementations:
- `MockAuthProvider` — deterministic auth state transitions
- `MockCloudSync` — tracks uploads without network
- `MockCrashReporter` — records errors in-memory

Run tests:
```bash
xcodebuild test -project Clera.xcodeproj -scheme Clera -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Production Release Checklist

- [ ] `GoogleService-Info.plist` is in `App/Resources/` (not committed to public repo)
- [ ] Firestore security rules are deployed
- [ ] Firebase Authentication sign-in methods are enabled
- [ ] App Store privacy labels mention authentication and crash reporting
- [ ] `NSAppTransportSecurity` allows Firebase endpoints (handled automatically)
- [ ] Test migration path on a device with existing local data
- [ ] Verify Crashlytics receives a test crash in Firebase Console
