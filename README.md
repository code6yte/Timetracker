# Smart Time Tracker (Flutter)

A compact Flutter app with Firebase integration for authentication and note tracking. This README gives a brief overview of features, how they are implemented, and where to find key code.

---

## Features ✅

- **Firebase Authentication** (email/password)
  - Implemented in `lib/auth_service.dart` using `firebase_auth`.
  - Exposes `signUp`, `login`, `logout`, and `resetPassword` methods that return error strings on failure.
  - UI flow: `lib/login_page.dart` handles sign-up/login UX and navigates to `HomeScreen` on success.

- **Notes (CRUD) using Cloud Firestore**
  - Implemented in `lib/firebase_service.dart`.
  - Methods: `addNote`, `getNotes` (stream of notes), `getNote`, `updateNote`, `deleteNote`.
  - Uses collection name `notes` by default; change `_collectionName` to modify.

- **Theme management (Light / Dark / System)**
  - Implemented in `lib/theme_controller.dart` as a singleton `ThemeController` (extends `ChangeNotifier`).
  - `ThemeController.setThemeMode(ThemeMode.mode)` updates the app theme and rebuilds via `AnimatedBuilder` in `main.dart`.

- **Responsive / Platform-ready project structure**
  - Supports Android, iOS, web, macOS, Windows, Linux (see platform folders).
  - Firebase configuration files (`google-services.json`, iOS plist, `firebase_options.dart`) are included in the repo.

- **UI helpers**
  - Reusable widgets (e.g., `GlassContainer` / `GlassScaffold`) used for the login and main UI (see `lib/widgets/`).

---

## How it works (flow) 💡

1. App starts in `main.dart` and initializes Firebase using `DefaultFirebaseOptions`.
2. `home` is a `StreamBuilder` listening to `FirebaseAuth.instance.authStateChanges()`:
   - If user is authenticated → `HomeScreen`.
   - Otherwise → `LoginPage`.
3. Login and sign-up call `AuthService` which communicates with Firebase Auth.
4. Notes are stored in Cloud Firestore; `FirebaseService.getNotes()` returns a live stream that the UI can listen to for updates.
5. Theme changes use `ThemeController` and notify the app via `AnimatedBuilder`.

---

## Files of interest 🔧

- `lib/main.dart` — App entry, Firebase init, theme wiring, auth-state routing.
- `lib/auth_service.dart` — Firebase Auth wrapper and helpers.
- `lib/firebase_service.dart` — Firestore CRUD wrapper (collection: `notes`).
- `lib/login_page.dart` — Login / Sign-up UI and behavior.
- `lib/theme_controller.dart` — Theme management singleton.
- `lib/widgets/` — Reusable UI components (e.g., `glass_container.dart`).
- `test/` — Basic widget tests (run with `flutter test`).

---

## Running & Testing ▶️

Prerequisites: Flutter SDK, platform toolchains, and Firebase project configured with this app (see `google-services.json` / iOS plist).

Commands:

- Fetch packages: `flutter pub get`
- Run on a device: `flutter run -d <device>`
- Run tests: `flutter test`

Debugging tips:
- Check logs for `Firebase initialization error:` messages (seen in `main.dart`).
- Auth methods return error messages that are shown as snackbars in the UI for quick feedback.

---

## Contributing & Notes

- Keep Firebase rules and indexes in sync with your Firestore usage.
- When changing backend collection names or schema, update `FirebaseService._collectionName` and related UI mapping.

---

If you want, I can expand this into a longer README (installation steps, screenshots, CI setup) or add inline docs and code comments. Let me know which sections you'd like expanded. ✨
