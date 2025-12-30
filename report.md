# **Project Report: Timely – Advanced Time Tracking Application**

## **2. Introduction**

### **Brief Overview**
**Timely** is a modern, cross-platform mobile application built using Flutter and Firebase, designed to help users track their productivity across various projects and tasks. It features a sleek "Glassmorphism" UI and provides real-time data synchronization with offline support.

### **Purpose and Scope**
The primary purpose of Timely is to provide a seamless interface for logging work hours, managing projects, and analyzing productivity trends. The scope includes secure user authentication, project/task organization, live timers (stopwatch and focus sessions), and automated report generation.

### **Target Audience**
*   **Freelancers:** To track billable hours for multiple clients.
*   **Students:** To manage study sessions and project timelines.
*   **Professionals:** To optimize their workday and identify time-wasters.

### **Problem Statement**
Many users struggle with "time blindness" or difficulty in manual logging. Existing solutions are often either too complex or lack real-time synchronization across devices. Timely solves this by offering a "one-tap" tracking experience with automated cloud syncing and intuitive gesture-based management.

---

## **3. Application Features & Functional Components**

*   **Secure Authentication:** Implements Firebase Auth with robust email validation (Regex-based), proactive "email-already-in-use" checks, and **Mandatory Email Verification** to ensure account authenticity.
*   **Guest Mode:** Allows users to explore the application and track time instantly using Firebase Anonymous Authentication, without the immediate need for an account.
*   **Complete CRUD Operations:** 
    *   **Projects:** Create, Read, Update, and Delete projects with customizable names, descriptions, and theme colors.
    *   **Tasks:** Manage tasks within specific projects or a global "Inbox."
*   **Database Integration:** 
    *   **Firebase Firestore:** Primary cloud database for real-time synchronization.
    *   **Hive (Local DB):** High-performance local caching for full offline functionality.
*   **Timer & Focus Modes:** 
    *   **Stopwatch:** Standard count-up timer for manual logging.
    *   **Focus Sessions:** Pomodoro-style countdown timers for deep-work sessions.
*   **Advanced UI/UX:** 
    *   **Glassmorphism Design:** A modern, semi-transparent aesthetic using `BackdropFilter`.
    *   **Gesture-Driven Actions:** Swipe-right to edit, swipe-left to delete, and long-press for detailed views.
*   **Analytics & Reporting:** Dynamic charts (Day/Week/Month) showing hourly productivity and category distributions.
*   **Data Portability:** Feature to export all tracked time entries into a standardized CSV format.

---

## **4. Code Samples**

### **Secure Login & Validation**
Timely uses a combination of Regex and Firebase error handling to ensure high-quality user accounts.
```dart
// lib/login_page.dart - Email Validation Logic
final emailRegex = RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]...");
if (!emailRegex.hasMatch(email)) {
  AppUI.showSnackBar(context, 'Please enter a valid email address');
  return;
}

// Guest Mode Implementation
Future<void> _handleGuestSignIn() async {
  final error = await _authService.signInAnonymously();
  if (error == null) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen()));
  }
}
```

### **Email Verification Guard**
Ensures only verified users or guests can access the main features.
```dart
// lib/main.dart - Navigation Logic
if (snapshot.hasData && snapshot.data != null) {
  final user = snapshot.data!;
  if (user.emailVerified || user.isAnonymous) {
    return const HomeScreen();
  } else {
    return const EmailVerificationScreen();
  }
}
```

### **CRUD Implementation (Tasks)**
The `TimeTrackerService` abstracts the complexity of syncing Firestore with the local Hive cache.
```dart
// lib/services/time_tracker_service.dart
Future<void> createTask(String title, String desc, String pId, String pName, String color) async {
  await _firestore.collection('tasks').add({
    'userId': userId,
    'title': title,
    'description': desc,
    'projectId': pId,
    'category': pName,
    'color': color,
    'isActive': true,
  });
}
```

### **Gesture-Based UI Layout**
Implementation of the `Dismissible` widget for intuitive project management.
```dart
// lib/screens/tasks_tab.dart
return Dismissible(
  key: Key('project_$id'),
  direction: DismissDirection.horizontal,
  background: Container(color: Colors.blueAccent, child: Icon(Icons.edit)),
  secondaryBackground: Container(color: Colors.redAccent, child: Icon(Icons.delete)),
  confirmDismiss: (direction) async {
    if (direction == DismissDirection.startToEnd) {
      _showEditProjectDialog(project);
      return false; // Don't remove from list yet
    }
    return await AppUI.showConfirmDialog(context, title: 'Delete Project');
  },
  child: ProjectCard(...),
);
```

---

## **5. App Screenshots**
*(Please insert your screenshots in the following order)*

1.  **[Screenshot: Login Page]** – Showing the glassmorphism input fields and the logo.
2.  **[Screenshot: Signup Page]** – Demonstrating validation error messages.
3.  **[Screenshot: Home Screen/Dashboard]** – Showing the compact project cards and today's stats.
4.  **[Screenshot: Project Details]** – Detailed task list within a specific project.
5.  **[Screenshot: CRUD Interface]** – The "Edit Project" dialog with the new description field.
6.  **[Screenshot: Timer Tab]** – Showing an active focus session with the circular progress bar.
7.  **[Screenshot: Reports Screen]** – The bar charts and category distribution heatmap.

---

## **6. Testing & Validation**

### **Testing Strategy**
The application underwent rigorous functional testing and static analysis.
*   **Static Analysis:** Used `flutter analyze` to ensure code quality and adherence to Dart best practices.
*   **Functional Testing:** Manually verified every CRUD operation and authentication flow.

### **Key Test Cases**
*   **Authentication:** Verified that dummy emails (e.g., `test@example.com`) are blocked and registered emails prompt a login.
*   **Sync Logic:** Tested task creation while offline; verified data successfully synced to Firestore once the connection was restored.
*   **Gestures:** Confirmed that swipe actions trigger the correct dialogs and long-presses navigate to detail screens.

### **Bugs Fixed & Features Added**
*   **Email Verification:** Implemented a mandatory verification flow to prevent unverified accounts from using the core features.
*   **Guest Access:** Added a "Guest Mode" using Firebase Anonymous login to lower the barrier for new users.
*   **Email Validation:** Fixed a bug where generic Firebase errors were shown instead of user-friendly registration warnings.
*   **Layout Issues:** Resolved a UI bug where top-bar content was hidden behind the mobile status bar using `SafeArea`.
*   **Class Encapsulation:** Fixed syntax errors in the Tasks tab that prevented the app from compiling.

---

## **7. Conclusion**

Through the development of **Timely**, I have gained deep experience in integrating Firebase services with local caching mechanisms like Hive. The project highlights the importance of responsive UI design and intuitive user feedback through gestures. 

The app provides significant value by centralizing productivity data into a visually appealing and fast interface. Future improvements could include push notification reminders for active timers and a "Dark Mode" auto-scheduler. While the app is currently robust in its CRUD and tracking capabilities, its primary limitation is the lack of a collaborative team-tracking feature, which remains a goal for version 2.0.

---
