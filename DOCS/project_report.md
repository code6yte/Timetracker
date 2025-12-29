# Project Report: Smart Time Tracker

## 1. Title Page

**Project Title:** Smart Time Tracker
**Student Name(s):** [Your Name]
**Registration Number(s):** [Your Reg. No.]
**Course Name:** Mobile Application Development
**Course Code:** [Course Code]
**Instructor Name:** [Instructor Name]
**Semester & Section:** [Semester/Section]
**Date of Submission:** December 24, 2025

---

## 2. Introduction

### Overview
**Smart Time Tracker** is a mobile application I developed using the Flutter framework. It’s a tool designed to help people keep track of their daily activities and projects in real-time. By integrating Firebase, I was able to ensure that all user data is securely stored in the cloud and synced across devices, making the experience seamless whether you're on your phone or tablet.

### Purpose and Scope
I built this project because I noticed how difficult it can be to keep track of where time actually goes during the day. We often wonder why we weren't productive, but without data, it's hard to improve. The scope of this project was to create a "digital mirror" for time usage—simple enough for daily use but powerful enough to provide meaningful insights through statistics.

### Target Audience
*   **Students:** To keep track of how many hours are spent studying versus leisure.
*   **Freelancers:** To accurately log billable hours for different clients.
*   **Professionals:** Anyone looking to improve their work-life balance by analyzing their daily routine.

### Problem Statement
The main problem this app solves is "time blindness." Many existing time-tracking apps are either too complex (geared towards enterprise) or too simple (local storage only). My goal was to build a middle ground: a personal, privacy-focused tracker that protects your data in the cloud while offering the detailed analytics usually reserved for paid software.

---

## 3. Application Features & Functional Components

### 1. Secure Authentication
For user security, I implemented **Firebase Authentication**.
*   **How it works:** Users can create an account using their email and password. I added error handling to give feedback if the password is too weak or the email is already in use.
*   **Why I chose it:** It abstracts away the complexity of managing sessions and provides a secure, industry-standard way to handle logins.

### 2. Database Integration (Cloud Firestore)
I chose **Cloud Firestore** as the database because its real-time capabilities fit perfectly with a time-tracking app.
*   **Data Structure:** I structured the database into collections for `users`, `projects`, `tasks`, and `time_entries`.
*   **Real-time Sync:** By using Flutter's `StreamBuilder`, any change made to the database (like stopping a timer) is instantly reflected on the UI without the user needing to refresh the page.

### 3. CRUD Operations
The core of the app revolves around standard CRUD (Create, Read, Update, Delete) functionality:
*   **Create:** Users can add new tasks and projects.
*   **Read:** The app fetches and displays lists of active tasks and historical time logs.
*   **Update:** If a mistake is made, users can edit task details (like fixing a typo in the title).
*   **Delete:** I implemented a "soft delete" feature where tasks are marked as inactive rather than permanently erased, preserving the history of time spent on them.

### 4. Real-time Search and Filtering
To make the data useful, I added search and filter capabilities on the "Reports" screen.
*   **Search:** A text field allows users to quickly find logs by task name.
*   **Filtering:** Users can drill down into their data by selecting specific **Date Ranges** or **Categories** (e.g., seeing only "Work" related logs).

### 5. Responsive UI & Navigation
I wanted the app to look modern, so I used a "Glassmorphism" design language with semi-transparent containers (`GlassContainer`).
*   **Navigation:** A persistent bottom navigation bar allows quick switching between the Timer, Tasks list, and Reports.
*   **Theming:** I added a `ThemeController` to support both Light and Dark modes, respecting the user's system preference.

### 6. Analytics & Visualization
This is where the app provides value. I implemented custom charts to visualize productivity:
*   **Heatmap:** Shows which days of the month were most productive.
*   **Timeline:** A horizontal bar that shows exactly what happened during the last 24 hours.
*   **Hourly Chart:** A bar graph displaying productivity peaks throughout the day.

---

## 4. Code Samples

### Login Function (`lib/login_page.dart`)
This function handles the logic for signing a user in or up. I focused on providing immediate feedback (like the loading spinner) to keep the UI responsive.
```dart
Future<void> _handleAuth() async {
  if (emailController.text.isEmpty || passwordController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill in all fields')),
    );
    return;
  }

  setState(() => isLoading = true);
  
  String? error;
  if (isSignUp) {
    error = await _authService.signUp(
      emailController.text.trim(),
      passwordController.text,
    );
  } else {
    error = await _authService.login(
      emailController.text.trim(),
      passwordController.text,
    );
  }

  setState(() => isLoading = false);

  if (error == null) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomeScreen())
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }
}
```

### Database Query: Filtered Entries (`lib/services/time_tracker_service.dart`)
This was one of the more complex parts of the backend logic. It listens to the database stream and filters the results on the client side based on the selected criteria.
```dart
Stream<List<TimeEntry>> getFilteredEntries({
  String? query,
  String? category,
  DateTime? startDate,
  DateTime? endDate,
}) {
  return _firestore
      .collection('time_entries')
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((snapshot) {
        var entries = snapshot.docs
            .map((doc) => TimeEntry.fromMap(doc.id, doc.data()))
            .toList();

        // Client-side filtering
        if (query != null && query.isNotEmpty) {
          entries = entries.where((e) => 
            e.taskTitle.toLowerCase().contains(query.toLowerCase())).toList();
        }
        if (category != null && category != 'All') {
          entries = entries.where((e) => e.category == category).toList();
        }
        
        return entries;
      });
}
```

---

## 5. App Screenshots

*(Please refer to the attached screenshots in the submission folder for the visual representation.)*

1.  **Login Page:** Clean interface with glassmorphic cards for Email/Password entry.
2.  **Home Screen / Timer:** The main dashboard showing the currently running timer and quick access to recent tasks.
3.  **Tasks List:** A scrollable list where users can manage their active tasks and projects.
4.  **Reports Interface:** The filtering screen with the date picker and category dropdowns.
5.  **Analytics:** The visual charts (Timeline and Heatmap) that display user productivity data.

---

## 6. Testing & Validation

### Functional Testing
Since this is a solo project, I performed manual testing throughout the development lifecycle. My process involved:
1.  **Authentication Flow:** I created multiple test accounts to ensure the sign-up and login processes were robust and handled errors (like wrong passwords) gracefully.
2.  **Data Consistency:** I frequently checked the Firebase Console while using the app to ensure that data was being written exactly as expected.
3.  **Sync Testing:** I installed the app on two different emulators. I started a timer on one and watched it update on the other to verify the real-time sync.

### Test Cases & Results
| Feature | Test Case | Expected Result | Actual Result |
| :--- | :--- | :--- | :--- |
| **Login** | Enter valid email and password | Navigate to Home Screen | **Pass** |
| **Create Task** | Click "Add", enter details, save | Task appears in list & Firestore | **Pass** |
| **Timer Logic** | Start timer, wait 1 min, stop | Entry saved with ~60s duration | **Pass** |
| **Filtering** | Select "Work" category in Reports | Only "Work" entries are shown | **Pass** |

### Bugs Found & Fixed
One interesting bug I encountered was with the timer duration. Initially, I was calculating duration by counting seconds in the app. However, if the app was closed, the timer "stopped."
*   **Fix:** I changed the logic to store the `startTime` timestamp in the database. Now, the duration is calculated dynamically (`Now - StartTime`), so it remains accurate even if the app is closed or the phone restarts.

---

## 7. Conclusion

Building **Smart Time Tracker** was a challenging but rewarding experience. It pushed me to better understand the Flutter framework, especially how to manage state effectively across different screens.

**Key Learnings:**
*   I gained a deep appreciation for **asynchronous programming**. Handling Futures and Streams correctly was crucial for a smooth user experience.
*   Integrating **Firebase** taught me about NoSQL database structures and the importance of securing database rules.

**Future Improvements:**
If I were to continue working on this, I would love to add **Push Notifications** to remind users to take breaks. I also think a **Web Dashboard** would be a great addition, allowing users to view their reports on a larger screen.

Overall, this app successfully solves the problem of "time blindness" by providing a tool that is both easy to use and rich in data, and I'm proud of the final result.
