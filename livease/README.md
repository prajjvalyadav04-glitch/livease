# LivEase - Smart Society Companion App

A Flutter + Firebase app for residential communities. Residents pre-approve
visitors with QR passes, raise maintenance complaints with photos, read notices
and book amenities. Guards scan passes at the gate. Admins post notices and
manage complaints.

## Features

| Feature | What it does |
|---|---|
| **OTP login** | Phone number + SMS code (Firebase Auth). First login collects name and flat number. |
| **Roles** | `resident`, `guard`, `admin`. Each role gets its own tabs, and the roles are enforced by Firestore security rules, not just hidden buttons. |
| **Visitor QR passes** | Resident creates a pass (name, purpose, 2/6/24h validity) and gets a QR. The guard scans it. Passes are single-use and expire automatically. |
| **Complaints** | Raise an issue with category, description and an optional photo (compressed before upload). Status moves Open -> In progress -> Resolved. Admin updates the status and the resident gets a push. |
| **Notice board** | Admin posts announcements (pinnable). Every resident gets a push notification. |
| **Amenity booking** | Pick a facility, a day in the next 14 days and a free slot. Double bookings are impossible (see "Technical decisions"). |

## Tech stack

- Flutter (Material 3, light + dark theme) and Dart 3
- **Riverpod** for state management and dependency injection
- **go_router** with auth-aware redirects
- Firebase: Auth (phone), Cloud Firestore, Storage, Cloud Messaging, Cloud Functions
- `qr_flutter` (generate QR), `mobile_scanner` (scan QR), `image_picker`, `cached_network_image`

## Project structure

```
lib/
  main.dart, app.dart          app entry, MaterialApp.router, theming
  core/                        router, theme, shared providers and widgets
  services/                    FCM / push notification service
  features/                    feature-first modules
    auth/                      login (OTP), profile setup, user model
    home/                      role-based bottom navigation
    notices/                   notice board + admin posting
    visitors/                  QR passes (resident) + scanner (guard)
    complaints/                complaints with photo + status tracking
    amenities/                 amenity booking with slot conflict check
functions/                     Cloud Functions that send push notifications
firestore.rules                Firestore security rules
storage.rules                  Storage security rules
test/                          unit and widget tests
```

Each feature keeps its model, repository (Firestore access) and screens
together. Screens never talk to Firebase directly; they go through repository
providers, which keeps the UI testable and easy to follow.

## Setup

### 1. Prerequisites

- Flutter SDK (stable), Node.js 20+, a Firebase project
- Firebase CLI: `npm i -g firebase-tools`
- FlutterFire CLI: `dart pub global activate flutterfire_cli`

### 2. Generate the platform folders and connect Firebase

This repo contains the Dart code and Firebase config. Create the Android/iOS
runner folders, then connect your Firebase project:

```bash
flutter create --platforms=android,ios .
flutter pub get
firebase login
flutterfire configure        # overwrites lib/firebase_options.dart
```

### 3. Enable Firebase services (console)

1. **Authentication -> Sign-in method -> Phone**: enable it.
   For development add **test phone numbers** (e.g. +91 90000 00001 with code
   123456) so you do not burn real SMS quota.
2. **Android only**: add your debug **SHA-1 and SHA-256** in Project settings
   (`cd android && ./gradlew signingReport`), then re-run `flutterfire configure`.
3. **Firestore Database**: create in production mode.
4. **Storage**: enable it.
5. Cloud Functions need the **Blaze (pay-as-you-go)** plan. The free tier is
   generous for a demo.

### 4. Platform settings

- **Android** `android/app/build.gradle`: set `minSdkVersion` to **23** or higher.
- **iOS** `ios/Runner/Info.plist`: add
  `NSCameraUsageDescription` (QR scanning and complaint photos) and
  `NSPhotoLibraryUsageDescription` (choosing a photo). Push on iOS also needs an
  APNs key uploaded in Firebase Console -> Cloud Messaging.

### 5. Deploy rules and functions

```bash
cd functions && npm install && cd ..
firebase deploy --only firestore:rules,storage,functions
```

### 6. Create a guard and an admin

New accounts are always residents (the rules block self-promotion). To create
a guard or admin: sign in once with that phone number and finish profile setup,
then open **Firestore -> users -> (that user's document)** and change the
`role` field to `guard` or `admin`. The app picks it up instantly.

### 7. Run

```bash
flutter run
flutter test
flutter analyze
```

## Technical decisions

- **Why Riverpod?** Providers make dependencies explicit and overridable in
  tests, and `StreamProvider` fits Firestore's real-time snapshots perfectly.
- **Why go_router with redirects?** One place (`core/router.dart`) decides
  whether you see login, profile setup or home, based on auth + profile state.
  Screens never need to check "am I logged in?".
- **Double-booking prevention.** A booking's document id is
  `amenity_date_slot`. The booking runs in a Firestore **transaction** that
  checks the document does not exist, and the **security rules** only allow
  `create` (never `update`) on `bookings`, so even a tampered client cannot
  overwrite someone else's slot.
- **Single-use visitor passes.** The guard's scan runs in a **transaction** that
  reads the pass, checks it is active and unexpired, and marks it used. Two
  guards scanning at the same moment cannot both approve it. Rules limit guards
  to flipping `active -> used`; they cannot edit visitor details.
- **Expiry without a background job.** Passes store `expiresAt`; "expired" is
  computed when read, so there is nothing to schedule or clean up.
- **Roles enforced server-side.** Users cannot change their own `role`;
  admin-only actions (posting notices, changing complaint status) are checked
  in `firestore.rules`.
- **Push notifications.** Residents subscribe to the `society` FCM topic.
  A Cloud Function publishes to it when a notice is created, and another sends
  a direct push to the complaint owner when the status changes.
- **Photo upload.** Photos are resized (1280px) and compressed (70% quality)
  at pick time, then uploaded to `complaints/{uid}/...`. Storage rules allow
  images only, up to 5 MB, in the user's own folder.
- **No composite indexes.** Queries use equality filters only and sort on the
  client, so the project runs without any manual index setup.

## Known limitations / ideas for next steps

- Complaint photo upload and Firestore writes need a network connection
  (Firestore's offline cache covers reads and queues simple writes).
- Notification taps open the app but do not yet deep-link to the specific
  notice or complaint.
- Ideas: maintenance bills with a payment gateway, a resident chat, admin
  analytics dashboard, Hindi localisation, GitHub Actions CI
  (`flutter analyze` + `flutter test` + `flutter build apk`).
