# Screens & Components Reference — Smart Time Tracker

This document describes every screen and key UI component in the project, how they work, data flows, important methods they call, and notes for maintenance or improvements. Use this as a developer quick reference. ✅

---

## Table of contents
- Screens
  - `HomeScreen` (Dashboard & root navigation)
  - `TasksTab` (Projects & Inbox)
  - `TimerTab` (Stopwatch & Focus)
  - `ProjectDetailsScreen` (Single project tasks)
  - `ReportsScreen` (Advanced reports & filters)
  - `StatisticsTab` (Summary, export)
  - `SettingsScreen` (Profile, appearance, account)
  - `LoginPage` (Auth flow)
- Reusable Components & Helpers
  - `GlassContainer`, `GlassScaffold`
  - `ThemeController`
  - Services: `AuthService`, `FirebaseService`, `TimeTrackerService`
  - Models: `Task`, `Project`, `TimeEntry`, `Category`

---

## Screens

### HomeScreen (lib/screens/home_screen.dart) 🔧
- Purpose: Root landing screen showing dashboard stats, recent projects, recent tasks, persistent stop/stopwatch UI and tab navigation.
- Main responsibilities:
  - Provides bottom navigation to Projects (TasksTab), TimerTab, ReportsScreen, SettingsScreen.
  - Dashboard widgets: "Today" (hours tracked) and "Tasks" (count) — driven by streams from `TimeTrackerService.getTodayEntries()` and `getTasks()`.
  - Lists recent projects (3) and recent tasks (3) with in-place actions (open, edit, delete, start timer).
  - FloatingActionButtons:
    - Add (right) → opens modal bottom sheet to add Project or Task.
    - Stop (left) → appears when a running non-focus timer exists (stops timer).
- Data sources / streams:
  - `TimeTrackerService.getProjects()` — project list
  - `TimeTrackerService.getTasks()` — task list
  - `TimeTrackerService.getRunningTimer()` — running timer
  - `TimeTrackerService.getTodayEntries()` — today's entries
- Key methods used:
  - `_showAddProjectDialog`, `_showAddTaskDialog`, `_showEditProjectDialog`, `_showEditTaskDialog` — create/edit flows use `TimeTrackerService.createProject`, `createTask`, `updateProject`, `updateTask`.
  - `_deleteProject` & task delete — use `TimeTrackerService.deleteProject` and `deleteTask`.
  - Start/Stop timer calls `TimeTrackerService.startTimer/stopTimer`.
- UX & edge cases:
  - Uses `Dismissible` with confirm delete dialogs and `PopupMenuButton` for actions.
  - Projects/tasks are presented with color accent and fallback color parsing via `_safeParseColor`.
- Notes:
  - Dashboard excludes "focus" sourced entries for the 'Today' stat.

---

### TasksTab (lib/screens/tasks_tab.dart) 🗂️
- Purpose: Main projects grid & Inbox tasks list; create/edit/delete projects and tasks.
- UI:
  - Action buttons for "New Project" and "Quick Task".
  - Projects shown in a GridView using `GlassContainer` with project icon and popup menu.
  - Inbox shows tasks (no project) with play button to start a timer and options to edit/delete.
- Data sources:
  - `TimeTrackerService.getProjects()`, `getInboxTasks()`, `getTasks()`.
- Key behaviors & methods:
  - `_showAddProjectDialog` → `createProject`
  - `_showAddTaskDialog` → `createTask`
  - `_showEditProjectDialog` → `updateProject`
  - `_showEditTaskDialog` → `updateTask`
  - Deletion uses `deleteProject` and `deleteTask` (soft delete sets `isActive = false`).
- Notes:
  - Projects use fixed `defaultColors` palette and UI shows selected color checkmark.

---

### TimerTab (lib/screens/timer_tab.dart) ⏱️
- Purpose: Stopwatch and Focus (Pomodoro-like) modes. Start/stop timers tied to tasks; focus uses an expected duration.
- UI:
  - TabBar with two modes: Stopwatch and Focus.
  - Task selector dropdown (from `getTasks()` stream) to pick a task to track.
  - Central timer display (large time text or circular progress for focus mode), and large circular action button (play/stop).
- Core logic:
  - Persistent running entry is read from `TimeTrackerService.getRunningTimer()` stream.
  - When starting a new timer, `startTimer` is called; this first calls `stopAllRunningTimers()` in the service to ensure single running timer.
  - For Focus sessions, an `expectedDuration` (e.g., 25 minutes) is provided; UI shows countdown and triggers `_handleFocusCompletion()` when done.
  - `_startRunningUpdateTimer()` uses a local `Timer.periodic` to update displayed seconds and watch for completion.
- Notes:
  - When a timer is running, the task dropdown is disabled.
  - Focus sessions set source = `'focus'` (used to differentiate UI behavior elsewhere).

---

### ProjectDetailsScreen (lib/screens/project_details_screen.dart) 📁
- Purpose: Show all tasks for a single project; add/edit/delete tasks; start timers for tasks in the context of project.
- Data source: `TimeTrackerService.getTasksByProject(project.id)` stream.
- Key actions:
  - Add Task → `createTask(projectId, projectName, project.color)`
  - Edit Task → `updateTask`
  - Delete Task → `deleteTask` (with confirmation dialog)
  - Start timer button triggers `startTimer` for the selected task.
- Notes: FloatingActionButton provided for quick add; UI adapts padding based on width.

---

### ReportsScreen (lib/screens/reports_screen.dart) 📊
- Purpose: Advanced reports UI: filters (search, date, category), heatmap, timeline, hourly productivity, detailed logs.
- Inputs & filters:
  - Text search (task title), date picker, category dropdown (uses `getCategories()` which maps projects to categories).
- Data & widgets:
  - Timeline built from `getTimeEntries(selectedDate, selectedDate)`.
  - Hourly productivity uses `getHourlyProductivity(date)`.
  - Logs list uses `getFilteredEntries(query, category, startDate, endDate)`.
  - Heatmap is currently a mocked visual (intent shown) based on `getWeeklySummary()` as a data fetch.
- Actions:
  - Tapping activity shows entry details dialog with start, duration, category.
  - Export/share is a placeholder (`_exportReports` shows a snackbar for now).
- Notes:
  - Many visualization elements are implemented with simple custom drawing using existing widgets (no external chart libs used).

---

### StatisticsTab (lib/screens/statistics_tab.dart) 📈
- Purpose: Quick summary and export (CSV sharing) features.
- Data sources:
  - `getTodayEntries()`, `getDailyGoal()`, `getWeeklySummary()`, `getTodayTimeByCategory()`.
- Features:
  - Today stats, weekly bar chart, category breakdown, daily goal progress (LinearProgressIndicator), export via `TimeTrackerService.exportToCSV()`.
- Notes:
  - Export uses `path_provider` and `csv` packages and `Share.shareXFiles` to let user share the exported file.

---

### SettingsScreen (lib/screens/settings_screen.dart) ⚙️
- Purpose: Profile editing, daily goal, appearance (ThemeMode), and account sign-out.
- Key integrations:
  - Profile display uses `AuthService().currentUser` and can call `user.updateDisplayName()`.
  - Daily goal stored via `TimeTrackerService.setDailyGoal()`/`getDailyGoal()`.
  - Theme selection uses `ThemeController.setThemeMode(...)` which notifies via `ChangeNotifier`.
  - Logout uses `AuthService().logout()` and routes back to `LoginPage`.
- Notes:
  - Appearance uses `SegmentedButton<ThemeMode>` to switch System/Light/Dark.

---

### LoginPage (lib/login_page.dart) 🔐
- Purpose: Sign-up and login using email/password; shows sign-in and sign-up forms with toggling mode.
- Auth integration:
  - Uses `AuthService.signUp`, `AuthService.login` which return `null` on success or an error string to show in a `SnackBar`.
  - On successful login, navigation replaces stack with `HomeScreen`.
- UI details:
  - Uses `GlassScaffold` and `GlassContainer` for background and layout styling.
  - Basic validation ensures both fields are non-empty; shows loader while authenticating.

---

## Reusable Components & Helpers

### GlassContainer & GlassScaffold (lib/widgets/glass_container.dart) ✨
- GlassContainer:
  - Purpose: Reusable frosted-glass style container with blur (`BackdropFilter`) and parameterized `opacity`, `color`, `borderRadius`, `padding`.
  - Inputs: `child`, `blur`, `opacity`, `color`, `padding`, `width`, `height`.
  - Visuals: Adds a border and subtle shadow; commonly used across all screens.
- GlassScaffold:
  - Purpose: Convenience wrapper that provides background gradient for dark mode and SafeArea wrapper.
  - Usage: Often used for standalone screens (e.g. `ProjectDetailsScreen` used inside `GlassScaffold`).

---

### ThemeController (lib/theme_controller.dart) 🎨
- Singleton `ChangeNotifier` exposing `themeMode` and `setThemeMode(ThemeMode)`.
- App uses `AnimatedBuilder` in `main.dart` subscribed to `ThemeController` to rebuild MaterialApp when theme changes.
- Note: Persistent storage (e.g., SharedPreferences) is not implemented — theme resets on app restart.

---

### AuthService (lib/auth_service.dart) 🔐
- Simple wrapper around `FirebaseAuth`:
  - `signUp(email, password)`, `login(email, password)`, `logout()`, `resetPassword(email)`.
  - Error handling returns error messages as strings.
- UI integration: Login and Settings use these methods; on error they show SnackBars.

---

### FirebaseService (lib/firebase_service.dart) 🗃️
- Purpose: Basic CRUD wrapper for a `notes` collection used by a small notes feature.
- Exposes: `addNote`, `getNotes()` (stream), `getNote`, `updateNote`, `deleteNote`.
- Note: The main application uses `TimeTrackerService` for projects/tasks/time entries; `FirebaseService` appears to be a separate notes helper.

---

### TimeTrackerService (lib/services/time_tracker_service.dart) — Primary backend integration ⚙️
- Responsibilities:
  - Projects: `createProject`, `getProjects`, `updateProject`, `deleteProject`.
  - Tasks: `createTask`, `getTasks`, `getTasksByProject`, `getInboxTasks`, `updateTask`, `deleteTask` (soft delete via `isActive`).
  - Time entries: `startTimer`, `stopTimer`, `stopAllRunningTimers`, `getRunningTimer`, `getTimeEntries`, `getTodayEntries`, `getWeekEntries`.
  - Analytics / Reports: `getTodayTimeByCategory`, `getWeeklySummary`, `getHourlyProductivity`, `getFilteredEntries`.
  - Export: `exportToCSV()` (stores file in app documents directory and returns path).
- Implementation notes:
  - The service scopes data by `userId` from `FirebaseAuth.currentUser`.
  - Some filtering calculations (date ranges, aggregation) are done in-memory after pulling user entries — acceptable for smaller datasets; consider server-side aggregation for very large datasets.

---

## Data Models
- Task (lib/models/task.dart) — fields: `id`, `userId`, `title`, `description`, `projectId`, `category`, `color`, `createdAt`, `isActive`.
- Project (lib/models/project.dart) — fields: `id`, `name`, `color`, `createdAt`.
- TimeEntry (lib/models/time_entry.dart) — fields: `id`, `userId`, `taskId`, `taskTitle`, `startTime`, `endTime`, `duration`, `category`, `isRunning`, `expectedDuration`, `source`.
- Category (lib/models/category.dart) — compatibility shim around Projects for older UI.

---

## Accessibility & UX notes 💡
- Many Texts are visible to screen readers; `Semantics` used in some places (e.g., Today stat hours). Consider adding more semantic labels for interactive buttons.
- Confirmations are used for deletions and logout.
- Error states show snackbars; some streams show spinners while waiting — consider unified error display patterns.

---

## Suggested Improvements / TODOs ✨
- Persist user-selected theme in `ThemeController` (SharedPreferences) so theme survives restarts.
- Move heavy aggregations to Firestore queries / Cloud Functions for scalability.
- Add tests for `TimeTrackerService` aggregation methods and for each screen's core behavior.
- Add screenshots and visual examples in docs and improve `ReportsScreen` heatmap implementation (real data-driven heatmap instead of mock).
- Add explicit permission checks and error handling for export & file IO for platforms like web.

---

## Where to extend or look next
- Add more unit tests under `test/` for `TimeTrackerService` and `AuthService`.
- To change visual theme palettes, update `defaultColors` lists in `home_screen.dart` and `tasks_tab.dart`.
- For export/analytics upgrades, look into `lib/services/time_tracker_service.dart` and `lib/screens/reports_screen.dart`.

---

If you'd like, I can: ✨
- Add inline doc comments to each screen file (Dart doc style), or
- Generate a smaller API reference snippet per service (methods + signatures), or
- Create README sections with screenshots and developer setup steps.

Tell me which of the above you'd like next and I'll implement it.