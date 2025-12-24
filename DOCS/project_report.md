# Smart Time Tracker — Project Report

---

## 1. Title Page ✅

**Project title:** Smart Time Tracker

**Student name(s) & registration number(s):** [Replace with student name(s) and reg. number(s)]

**Course name & course code:** [Replace with course name and course code]

**Instructor name:** [Replace with instructor name]

**Semester & Section:** [Replace with semester & section]

**Date of submission:** [Replace with submission date]

---

## 2. Introduction ✨

**Overview:**
Smart Time Tracker is a Flutter mobile application that helps users track time spent on tasks and projects. It supports creating projects and tasks, starting/stopping timers, logging manual time entries (e.g., Pomodoro sessions), and viewing reports and summaries of tracked time.

**Purpose & scope:**
The app was built to provide a lightweight, user-friendly time tracking solution for students and professionals to monitor productivity. Scope includes user authentication, persistent cloud storage (Firebase), task/project management, timing and logging functionality, and basic analytics and export.

**Target audience / users:**
- Students tracking study hours
- Freelancers or professionals tracking billable time
- Anyone interested in tracking time spent on different projects or tasks

**Problem statement:**
Many people need an unobtrusive way to record time spent on tasks and projects. This app solves the problem by offering simple start/stop timers, manual logging, project/task organization, and reporting to help users understand and improve their productivity.

---

## 3. Application Features & Functional Components 🔧

**Authentication:**
- Secure Login and Signup using Firebase Authentication (email + password).
- Auth state observed in `main.dart` via `FirebaseAuth.instance.authStateChanges()` to route users to Login or Home.

**CRUD operations & Database integration:**
- Database: Firebase Cloud Firestore (see `pubspec.yaml` dependencies: `cloud_firestore`).
- Projects: create, read (stream), update, delete (`TimeTrackerService.createProject`, `getProjects`, `updateProject`, `deleteProject`).
- Tasks: create, read (stream), update, soft-delete (`createTask`, `getTasks`, `updateTask`, `deleteTask` which sets `isActive=false`).
- Time entries: start/stop timers and log manual entries (`startTimer`, `stopTimer`, `logTimeEntry`).
- Real-time data: All list and dashboards use Firestore snapshots to provide live updates.

**Real-time search & filtering:**
- `getFilteredEntries` in `TimeTrackerService` supports filtering by query (task title), category, and date range. Search is implemented client-side filtering on snapshots for responsive results.

**Notifications & Push:**
- Push notifications are not implemented in the current version.

**Network/API calls:**
- No external REST APIs; all networking is via Firebase services (Firestore and Auth).

**Responsive UI & Navigation:**
- Adaptive UI using Material widgets, `GlassContainer` custom widget for consistent card styling, bottom navigation for Tabs (Projects / Timer / Reports / Settings), modals and dialogs for CRUD flows, and bottom sheet for quick add menu.

**Additional features / Utilities:**
- Export tracked data to CSV (`TimeTrackerService.exportToCSV`) using `csv` and `path_provider` packages.
- CSV file is saved in app documents folder for sharing/export purposes.
- Share functionality (package `share_plus`) is included in `pubspec.yaml` (used in export or reports UI where appropriate).

---

## 4. Code Samples (key excerpts) 💡

### Authentication — Login & Signup (excerpt)

```dart
// lib/auth_service.dart
Future<String?> login(String email, String password) async {
  try {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return null; // Success
  } on FirebaseAuthException catch (e) {
    return e.message ?? 'An error occurred';
  }
}
```

### CRUD Implementation — Tasks & Projects (excerpts)

```dart
// Create Project
Future<void> createProject(String name, String color) async {
  await _firestore.collection('projects').add({
    'userId': userId,
    'name': name,
    'color': color,
    'createdAt': DateTime.now().millisecondsSinceEpoch,
  });
}

// Create Task
Future<void> createTask(String title, String description, String projectId, String projectName, String color) async {
  await _firestore.collection('tasks').add({
    'userId': userId,
    'title': title,
    'description': description,
    'projectId': projectId,
    'category': projectName,
    'color': color,
    'createdAt': DateTime.now().millisecondsSinceEpoch,
    'isActive': true,
  });
}

// Soft-delete Task
Future<void> deleteTask(String taskId) async {
  await _firestore.collection('tasks').doc(taskId).update({
    'isActive': false,
  });
}
```

### Database queries & Streams (real-time updates)

```dart
// Projects stream
Stream<List<Project>> getProjects() {
  return _firestore
    .collection('projects')
    .where('userId', isEqualTo: userId)
    .snapshots()
    .map((snapshot) => snapshot.docs.map((doc) => Project.fromMap(doc.id, doc.data())).toList());
}
```

### Search & Filter logic

```dart
// getFilteredEntries supports query, category, startDate, endDate
if (query != null && query.isNotEmpty) {
  entries = entries.where((e) => e.taskTitle.toLowerCase().contains(query.toLowerCase())).toList();
}
```

### Export to CSV (snippet)

```dart
String csvData = const ListToCsvConverter().convert(rows);
final directory = await getApplicationDocumentsDirectory();
final file = File('${directory.path}/timetracker_export_...csv');
await file.writeAsString(csvData);
return file.path;
```


---

## 5. App Screenshots 📸

Please insert labelled screenshots below. Replace placeholders with actual images from the app.

- Login page: `assets/screenshots/login.png` (placeholder)
- Signup page: `assets/screenshots/signup.png` (placeholder)
- Home screen / Dashboard: `assets/screenshots/home.png` (placeholder)
- CRUD interface (Add/Edit Project/Task): `assets/screenshots/crud.png` (placeholder)
- Database output / Reports screen: `assets/screenshots/reports.png` (placeholder)
- Search results: `assets/screenshots/search_results.png` (placeholder)
- Any other important UI screens: `assets/screenshots/extra.png` (placeholder)

> Tip: Use `flutter run` on an emulator or device, take screenshots, and place them in the `assets/screenshots/` folder, then update this document with correct file names.

---

## 6. Testing & Validation ✅

**Functional testing steps:**
1. Install and run the app on Android/iOS emulator or device.
2. Sign up with a test email and password.
3. Create projects and tasks using the Add menu.
4. Start a timer for a task and stop it; verify entry appears in Reports.
5. Create manual log entries (Pomodoro or manual log) and verify their appearance.
6. Update and delete tasks/projects; ensure UI reflects changes.
7. Use search and filters on the Reports screen and confirm accurate results.
8. Export data to CSV and open the exported file to confirm data integrity.

**Test cases used:**
- Signup and Login success & failure (bad email, wrong password).
- Create project: valid name, blank name (should block creation).
- Create task assigned to project and to Inbox.
- Start/stop timer: ensure accurate duration and 'isRunning' flag toggles.
- Soft-delete task: ensure it disappears from active lists but remains in database.
- Export CSV: file exists and contains header + entries.

**Bugs found & fixes:**
- (Example) If Firebase initialization fails, the app logs the error (see try/catch in `main.dart`). Ensure `google-services.json` and proper Firebase config are set for the platform.
- Soft-delete behavior is intended; if a hard-delete is required, add a cascade delete for related records.

**Known issues / limitations:**
- No push notifications implemented.
- Some queries fetch all entries and filter client-side (could be optimized with server-side queries to reduce data transfer for large datasets).
- No unit/integration tests for business logic beyond the basic widget test.

---

## 7. Conclusion 🔚

This project taught practical skills in Flutter UI composition, state management with Streams, and integrating Firebase services (Auth & Cloud Firestore). The app provides immediate value by enabling users to track time, organize tasks into projects, analyze weekly/daily productivity, and export data for external use.

Future improvements may include:
- Adding push/notifications and reminders.
- Server-side optimized queries and pagination for large datasets.
- Offline sync and improved error handling for network failures.
- More robust test coverage (unit tests for `TimeTrackerService` and integration tests for flows).

**Strengths:** Clean UI, real-time updates, straightforward CRUD and timer features, and CSV export.

**Limitations:** Limited test coverage, missing notifications, and some client-side filtering inefficiencies.

---

### Appendix: Where to find key files 📂
- `lib/auth_service.dart` — authentication
- `lib/services/time_tracker_service.dart` — core CRUD & timer logic
- `lib/screens` — UI screens (home, tasks, timer, reports, settings)
- `pubspec.yaml` — dependencies
- `test/widget_test.dart` — basic smoke test

---

If you want, I can:
- Insert real screenshots into `assets/screenshots/` and update the report images, or
- Export the report as PDF for submission.

*Replace placeholders (student name, course details, screenshots) before final submission.*
