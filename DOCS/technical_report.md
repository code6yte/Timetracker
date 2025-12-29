# Technical Report: Dependencies & Project Architecture

## 1. Executive Summary
This document provides a detailed technical breakdown of the **Smart Time Tracker** application. It outlines the technology stack, external package dependencies, and the architectural decisions that drive the application's functionality. The project is built using **Flutter**, ensuring a high-performance, cross-platform experience on Android, iOS, and other supported platforms.

## 2. Technology Stack

*   **Framework:** Flutter (SDK version `^3.10.0`)
*   **Language:** Dart
*   **Backend / Serverless:** Firebase (Google Cloud Platform)
*   **State Management:** `StreamBuilder` & `ChangeNotifier` (Native Flutter approach)
*   **Architecture:** Service-Oriented Architecture (SOA) with MVVM-like separation.

---

## 3. Package Dependencies

The application relies on a curated list of reliable, industry-standard packages from [pub.dev](https://pub.dev). Below is an explanation of each dependency and its specific role in the project.

### 3.1 Firebase Ecosystem (Backend Services)
These packages enable the serverless architecture, handling authentication and data persistence.

*   **`firebase_core (^4.2.1)`**
    *   **Role:** The prerequisite package for all other Firebase plugins.
    *   **Usage:** It initializes the Firebase app instance (`Firebase.initializeApp()`) in `main.dart`, connecting the Flutter app to the Google project configuration.

*   **`cloud_firestore (^6.1.0)`**
    *   **Role:** Provides the API for Cloud Firestore, a NoSQL document database.
    *   **Usage:** Used extensively in `TimeTrackerService` to store user data. We utilize its **real-time capabilities** (snapshots) to instantly sync tasks and timers across devices without manual refresh.

*   **`firebase_auth (^6.1.2)`**
    *   **Role:** Manages user authentication.
    *   **Usage:** Handles account creation, sign-in, and session management. It provides the `authStateChanges()` stream, which the app listens to for redirecting users between the Login and Home screens.

*   **`firebase_database (^12.1.0)`**
    *   **Role:** Access to the Firebase Realtime Database.
    *   **Usage:** Included for potential future features requiring low-latency synchronization (e.g., collaborative live typing), though the primary data storage currently utilizes Firestore.

### 3.2 Utility Packages
These libraries handle specific functional requirements such as data formatting and file management.

*   **`intl (^0.19.0)`**
    *   **Role:** Internationalization and data formatting.
    *   **Usage:** Critical for formatting dates (e.g., "Mon, Dec 24") and times (e.g., "14:30") within the `ReportsScreen` and task lists.

*   **`path_provider (^2.1.1)`**
    *   **Role:** Access to the filesystem.
    *   **Usage:** Finds the correct directory on the user's device (e.g., AppDocuments on iOS/Android) to safely store temporary files, such as generated reports.

*   **`csv (^6.0.0)`**
    *   **Role:** CSV generation and parsing.
    *   **Usage:** Converts the list of `TimeEntry` objects into a comma-separated string, enabling the "Export to CSV" feature for users who want to analyze their data in Excel.

*   **`share_plus (^10.1.3)`**
    *   **Role:** Platform-native sharing dialogs.
    *   **Usage:** Allows the user to share the generated CSV report file via email, WhatsApp, or other apps installed on their device.

### 3.3 UI Dependencies
*   **`cupertino_icons (^1.0.8)`**
    *   **Role:** iOS-style icons.
    *   **Usage:** Ensures that the application adheres to Apple's Human Interface Guidelines when running on iOS devices.

---

## 4. Platform Configuration (Android)

The Android build configuration is managed in `android/app/build.gradle.kts` and adheres to modern Android development standards.

*   **Compile SDK:** Version **36** (Ensures compatibility with the latest Android 15 features).
*   **Target SDK:** Version **34** (Optimized for Android 14).
*   **Language Compatibility:**
    *   **Java:** Version 17
    *   **Kotlin:** Integrated via the `kotlin-android` plugin.
*   **Minimum SDK:** Determined dynamically by the Flutter framework, ensuring the app runs on the widest possible range of devices (typically Android 5.0+).

---

## 5. Architectural Overview

The project follows a **Service-Layer Architecture** to ensure maintainability and separation of concerns.

### 5.1 Layered Structure
1.  **Presentation Layer (`lib/screens/`, `lib/widgets/`)**:
    *   Contains the UI code.
    *   **Glassmorphism:** A custom UI theme implemented via `GlassContainer` and `GlassScaffold` to provide a distinct visual identity.
    *   **Reactive:** Widgets like `StreamBuilder` listen to the Service Layer and rebuild automatically when data changes.

2.  **Service Layer (`lib/services/`)**:
    *   **`AuthService`**: Wraps `FirebaseAuth` logic. It decouples the UI from the specific authentication provider, making it easier to mock for testing or swap providers later.
    *   **`TimeTrackerService`**: The "brain" of the application. It handles business logic (calculating durations, filtering dates) and communicates directly with Firestore.

3.  **Data Model Layer (`lib/models/`)**:
    *   Contains Dart classes (`Task`, `TimeEntry`, `Project`) that map Firestore documents to strongly-typed objects. This prevents "magic string" errors and improves code readability.

### 5.2 Development Tools
*   **`flutter_lints (^6.0.0)`**: A dev dependency that enforces the official Dart style guide. It ensures code quality by flagging potential issues (like missing const constructors or unused variables) before they become bugs.
