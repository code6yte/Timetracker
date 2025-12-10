# Smart Time Tracker - Quick Start Guide

## 🚀 Running the App

The app is currently running at: **http://localhost:8080**

If you need to restart:
```bash
flutter run -d web-server --web-port 8080
```

---

## 📋 How to Use

### 1. **First Time Setup**
1. Open http://localhost:8080
2. Click "Sign Up"
3. Enter email and password
4. Click "Sign Up" button
5. You're logged in!

### 2. **Create Your First Task**
1. Go to **Tasks** tab (bottom navigation)
2. Click the **+** button (bottom right)
3. Enter task name (e.g., "Study Math")
4. Add description (optional)
5. Select category (Work, Study, Personal, etc.)
6. Choose a color
7. Click "Add Task"

### 3. **Start Tracking Time**
1. Go to **Timer** tab
2. Click "Start Timer"
3. Select a task from the list
4. Timer starts automatically!
5. Do your work...
6. Click "Stop Timer" when done

### 4. **View Statistics**
1. Go to **Statistics** tab
2. See today's total time
3. View weekly bar chart
4. Check category breakdown

---

## 🎯 Quick Features Overview

| Feature | Location | Action |
|---------|----------|--------|
| **Create Task** | Tasks tab | Click + button |
| **Delete Task** | Tasks tab | Click trash icon |
| **Start Timer** | Timer tab | Click "Start Timer" |
| **Stop Timer** | Timer tab | Click "Stop Timer" |
| **View Stats** | Statistics tab | Automatic display |
| **Logout** | Any screen | Click logout icon (top right) |

---

## 🔥 Firebase Console Access

To manage your data and security:

1. Go to https://console.firebase.google.com/
2. Select project: **mobile-643dc**
3. Navigate to:
   - **Firestore Database** → View/edit data
   - **Authentication** → See users
   - **Rules** → Update security

### Recommended Firestore Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    match /tasks/{taskId} {
      allow create: if request.auth != null && 
                       request.resource.data.userId == request.auth.uid;
      allow read, update, delete: if request.auth != null && 
                                     resource.data.userId == request.auth.uid;
    }
    
    match /time_entries/{entryId} {
      allow create: if request.auth != null && 
                       request.resource.data.userId == request.auth.uid;
      allow read, update, delete: if request.auth != null && 
                                     resource.data.userId == request.auth.uid;
    }
  }
}
```

---

## 💡 Tips & Tricks

### Maximize Productivity
- ✅ Create tasks for all activities
- ✅ Use different categories to organize
- ✅ Pick distinct colors for quick identification
- ✅ Stop timer when taking breaks
- ✅ Review weekly stats regularly

### Best Practices
- 📝 Name tasks clearly
- 🎨 Use color coding consistently
- 📊 Check statistics daily
- ⏰ Track in focused blocks
- 🔄 Review and adjust weekly

---

## 🎨 Category Suggestions

| Category | Use For | Color |
|----------|---------|-------|
| **Work** | Job tasks, meetings | Blue |
| **Study** | Learning, courses | Green |
| **Personal** | Hobbies, errands | Orange |
| **Exercise** | Workouts, sports | Purple |
| **Other** | Misc activities | Red |

---

## 📊 Understanding Your Data

### Today's Summary (Timer Tab)
- Shows total time tracked today
- Updates in real-time as you work
- Counts completed sessions

### Weekly Chart (Statistics Tab)
- 7 bars = last 7 days
- Height = hours worked
- Compare daily productivity
- Identify patterns

### Category Breakdown (Statistics Tab)
- Shows time per category
- Percentage of total time
- Color-coded bars
- Updated for today only

---

## 🐛 Troubleshooting

### Timer Won't Start
- ✅ Make sure you created at least one task
- ✅ Check internet connection
- ✅ Refresh the page

### Data Not Showing
- ✅ Verify you're logged in
- ✅ Check Firestore rules allow read access
- ✅ Wait a few seconds for sync

### Can't Create Task
- ✅ Task name is required (not empty)
- ✅ Check internet connection
- ✅ Verify Firestore rules allow write access

### Timer Showing Wrong Time
- ✅ Refresh the page
- ✅ Check your system time is correct
- ✅ Stop and restart the timer

---

## 📱 Keyboard Shortcuts

- **Ctrl + Shift + R** - Hot reload (during development)
- **Tab** - Navigate between fields
- **Enter** - Submit forms
- **Esc** - Close dialogs

---

## 🔐 Security Tips

### For Production Use
1. **Never share** your Firebase config publicly
2. **Always use** Firestore security rules
3. **Enable** email verification
4. **Use strong** passwords
5. **Logout** when done

### Current Setup
- ✅ Each user can only see their own data
- ✅ Firebase Authentication required
- ✅ Secure HTTPS connection
- ✅ Password encryption automatic

---

## 📖 File Structure Guide

```
lib/
├── models/               # Data structures
│   ├── task.dart        # Task model
│   └── time_entry.dart  # Time entry model
│
├── services/            # Business logic
│   ├── time_tracker_service.dart  # Main service
│   └── auth_service.dart          # Login/logout
│
├── screens/             # UI pages
│   ├── home_screen.dart      # Main container
│   ├── tasks_tab.dart        # Task list
│   ├── timer_tab.dart        # Timer controls
│   └── statistics_tab.dart   # Analytics
│
├── login_page.dart      # Login/signup UI
├── main.dart           # App entry point
└── firebase_options.dart  # Firebase config
```

---

## 🎓 For Your Presentation

### Demo Script (5 minutes)

**1. Introduction (30s)**
"Smart Time Tracker helps users manage their time effectively using Flutter and Firebase."

**2. Authentication (30s)**
- Show login page
- Sign in with test account
- Explain Firebase Auth integration

**3. Create Task (1 min)**
- Navigate to Tasks tab
- Create a task with category
- Show color coding
- Explain Firestore storage

**4. Track Time (1.5 min)**
- Go to Timer tab
- Start timer on task
- Show real-time countdown
- Explain local timer + Firestore sync
- Stop timer

**5. View Statistics (1.5 min)**
- Navigate to Statistics tab
- Show today's total
- Explain weekly chart
- Show category breakdown
- Mention real-time updates via StreamBuilder

**6. Architecture (30s)**
"The app uses Flutter for UI, Firebase for backend, with Stream-based reactive architecture for real-time updates."

### Key Points to Emphasize
- ✅ Real-time synchronization
- ✅ Clean architecture (MVC pattern)
- ✅ Firebase security rules
- ✅ StreamBuilder for reactive UI
- ✅ User-specific data isolation

---

## 🆘 Quick Commands

```bash
# Start the app
flutter run -d web-server --web-port 8080

# Hot reload (during development)
Press 'r' in terminal

# Stop the app
Press 'q' in terminal

# Get dependencies
flutter pub get

# Clean build
flutter clean

# Format code
flutter format lib/

# Check for errors
flutter analyze
```

---

## 📞 Support Resources

- **Flutter Docs**: https://docs.flutter.dev/
- **Firebase Docs**: https://firebase.google.com/docs
- **Firestore Guide**: https://firebase.google.com/docs/firestore
- **Firebase Auth**: https://firebase.google.com/docs/auth

---

## ✅ Pre-Viva Checklist

Before your viva, make sure:
- [ ] App is running smoothly
- [ ] You can create tasks
- [ ] Timer starts and stops correctly
- [ ] Statistics show data
- [ ] You understand the code structure
- [ ] You know how Firebase works
- [ ] You can explain StreamBuilder
- [ ] Firestore rules are configured
- [ ] You've tested all features
- [ ] You can demo confidently

---

**App URL**: http://localhost:8080

**Good luck! 🎉**
