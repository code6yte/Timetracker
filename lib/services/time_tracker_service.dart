import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/task.dart';
import '../models/time_entry.dart';
import '../models/category.dart';
import '../models/project.dart';

class TimeTrackerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId => _auth.currentUser?.uid ?? '';

  // ========== PROJECT OPERATIONS (Formerly Categories) ==========

  Future<void> createProject(String name, String color) async {
    await _firestore.collection('projects').add({
      'userId': userId,
      'name': name,
      'color': color,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Stream<List<Project>> getProjects() {
    return _firestore
        .collection('projects')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Project.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  Future<void> deleteProject(String id) async {
    // Ideally we should check for tasks in this project first or cascade delete
    // For now, keeping it simple as per requirements
    await _firestore.collection('projects').doc(id).delete();
  }

  Future<void> updateProject(String id, String name, String color) async {
    await _firestore.collection('projects').doc(id).update({
      'name': name,
      'color': color,
    });
  }

  // Keeping Category methods for backward compatibility if needed,
  // but logically we are shifting to Projects.
  // ... [Legacy Category Methods omitted to encourage Project use] ...
  Stream<List<Category>> getCategories() {
    // Shim: Return projects as categories for UI compatibility during refactor
    return getProjects().map(
      (projects) => projects
          .map(
            (p) => Category(
              id: p.id,
              userId: userId,
              name: p.name,
              color: p.color,
              icon: 'folder',
            ),
          )
          .toList(),
    );
  }

  // ========== GOAL OPERATIONS ==========

  Future<void> setDailyGoal(int seconds) async {
    await _firestore.collection('user_settings').doc(userId).set({
      'dailyGoal': seconds,
    }, SetOptions(merge: true));
  }

  Stream<int> getDailyGoal() {
    return _firestore.collection('user_settings').doc(userId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return 8 * 3600; // Default 8 hours
      return (snapshot.data()?['dailyGoal'] ?? 8 * 3600) as int;
    });
  }

  // ========== TASK OPERATIONS ==========

  // Create a new task linked to a Project (category field used as project ID/Name storage for simplicity, or we add projectId)
  // To keep it simple in transition, 'category' field in Task will store the Project Name,
  // and we'll add 'projectId' as a new field.
  Future<void> createTask(
    String title,
    String description,
    String projectId,
    String projectName, // Using this for display and 'category' field compat
    String color,
  ) async {
    await _firestore.collection('tasks').add({
      'userId': userId,
      'title': title,
      'description': description,
      'projectId': projectId,
      'category':
          projectName, // Maintaining legacy field for stats compatibility
      'color': color,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'isActive': true,
    });
  }

  // Get all tasks for current user
  Stream<List<Task>> getTasks() {
    return _firestore
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final tasks = snapshot.docs
              .map((doc) => Task.fromMap(doc.id, doc.data()))
              .toList();
          tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return tasks;
        });
  }

  // Get tasks for a specific Project
  Stream<List<Task>> getTasksByProject(String projectId) {
    return _firestore
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .where('projectId', isEqualTo: projectId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final tasks = snapshot.docs
              .map((doc) => Task.fromMap(doc.id, doc.data()))
              .toList();
          tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return tasks;
        });
  }

  // Get tasks without a project (Inbox)
  Stream<List<Task>> getInboxTasks() {
    return _firestore
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .where('projectId', isEqualTo: '')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final tasks = snapshot.docs
              .map((doc) => Task.fromMap(doc.id, doc.data()))
              .toList();
          tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return tasks;
        });
  }

  // Update task
  Future<void> updateTask(
    String taskId,
    String title,
    String description,
    String projectId,
    String projectName,
  ) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'title': title,
      'description': description,
      'projectId': projectId,
      'category': projectName,
    });
  }

  // Delete task (soft delete)
  Future<void> deleteTask(String taskId) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'isActive': false,
    });
  }

  // Undo delete task
  Future<void> undoDeleteTask(String taskId) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'isActive': true,
    });
  }

  // ========== TIME ENTRY OPERATIONS ==========

  // Start timer for a task
  Future<String> startTimer(
    String taskId,
    String taskTitle,
    String category, {
    int? expectedDuration,
    String source = 'manual',
  }) async {
    // Stop any running timer first
    await stopAllRunningTimers();

    final doc = await _firestore.collection('time_entries').add({
      'userId': userId,
      'taskId': taskId,
      'taskTitle': taskTitle,
      'startTime': DateTime.now().millisecondsSinceEpoch,
      'endTime': null,
      'duration': 0,
      'category': category,
      'isRunning': true,
      'expectedDuration': expectedDuration,
      'source': source,
    });

    return doc.id;
  }

  // Stop timer
  Future<void> stopTimer(String entryId) async {
    final doc = await _firestore.collection('time_entries').doc(entryId).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final startTime = DateTime.fromMillisecondsSinceEpoch(data['startTime']);
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime).inSeconds;

    await _firestore.collection('time_entries').doc(entryId).update({
      'endTime': endTime.millisecondsSinceEpoch,
      'duration': duration,
      'isRunning': false,
    });
  }

  // Stop all running timers
  Future<void> stopAllRunningTimers() async {
    final runningTimers = await _firestore
        .collection('time_entries')
        .where('userId', isEqualTo: userId)
        .where('isRunning', isEqualTo: true)
        .get();

    if (runningTimers.docs.isEmpty) return;

    final batch = _firestore.batch();
    final endTime = DateTime.now();

    for (var doc in runningTimers.docs) {
      final data = doc.data();
      final startTime = DateTime.fromMillisecondsSinceEpoch(data['startTime']);
      final duration = endTime.difference(startTime).inSeconds;

      batch.update(doc.reference, {
        'endTime': endTime.millisecondsSinceEpoch,
        'duration': duration,
        'isRunning': false,
      });
    }

    await batch.commit();
  }

  // Get currently running timer
  Stream<TimeEntry?> getRunningTimer() {
    return _firestore
        .collection('time_entries')
        .where('userId', isEqualTo: userId)
        .where('isRunning', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return TimeEntry.fromMap(
            snapshot.docs.first.id,
            snapshot.docs.first.data(),
          );
        });
  }

  // Get time entries for a specific date range
  Stream<List<TimeEntry>> getTimeEntries(DateTime startDate, DateTime endDate) {
    final startOfDay = DateTime(startDate.year, startDate.month, startDate.day);
    final endOfDay = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
    );

    // Fetch all user entries and filter client-side to avoid composite index requirements
    return _firestore
        .collection('time_entries')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final entries = snapshot.docs
              .map((doc) => TimeEntry.fromMap(doc.id, doc.data()))
              .where((entry) {
                return entry.startTime.millisecondsSinceEpoch >=
                        startOfDay.millisecondsSinceEpoch &&
                    entry.startTime.millisecondsSinceEpoch <=
                        endOfDay.millisecondsSinceEpoch;
              })
              .toList();
          // Sort by start time
          entries.sort((a, b) => b.startTime.compareTo(a.startTime));
          return entries;
        });
  }

  // Get today's time entries
  Stream<List<TimeEntry>> getTodayEntries() {
    final now = DateTime.now();
    return getTimeEntries(now, now);
  }

  // Get this week's time entries
  Stream<List<TimeEntry>> getWeekEntries() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return getTimeEntries(startOfWeek, now);
  }

  // ========== ANALYTICS ==========

  // Get total time for today by category
  Future<Map<String, int>> getTodayTimeByCategory() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final entries = await _firestore
        .collection('time_entries')
        .where('userId', isEqualTo: userId)
        .get();

    final Map<String, int> categoryTime = {};

    for (var doc in entries.docs) {
      final data = doc.data();
      final startTimeMs = data['startTime'] as int? ?? 0;
      
      if (startTimeMs >= startOfDay.millisecondsSinceEpoch && 
          startTimeMs <= endOfDay.millisecondsSinceEpoch) {
          
        final category = data['category'] ?? 'Uncategorized';
        final duration = (data['duration'] ?? 0) as int;
        categoryTime[category] = (categoryTime[category] ?? 0) + duration;
      }
    }

    return categoryTime;
  }

  // Get weekly summary
  Future<List<Map<String, dynamic>>> getWeeklySummary() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekMidnight = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );
    final endOfWeek = now.add(
      Duration(days: 7 - now.weekday, hours: 23, minutes: 59, seconds: 59),
    );

    final List<Map<String, dynamic>> summary = [];

    // Fetch all entries for user
    final weekEntriesSnapshot = await _firestore
        .collection('time_entries')
        .where('userId', isEqualTo: userId)
        .get();

    final weekEntries = weekEntriesSnapshot.docs
            .map((doc) => TimeEntry.fromMap(doc.id, doc.data()))
            .where((entry) {
              return entry.startTime.millisecondsSinceEpoch >= 
                     startOfWeekMidnight.millisecondsSinceEpoch &&
                     entry.startTime.millisecondsSinceEpoch <= 
                     endOfWeek.millisecondsSinceEpoch;
            })
            .toList();

    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      int totalDuration = 0;
      for (var entry in weekEntries) {
        if (entry.startTime.isAfter(
              startOfDay.subtract(const Duration(seconds: 1)),
            ) &&
            entry.startTime.isBefore(endOfDay.add(const Duration(seconds: 1)))) {
          totalDuration += entry.duration;
        }
      }

      summary.add({
        'date': date,
        'duration': totalDuration,
        'hours': (totalDuration / 3600).toStringAsFixed(1),
      });
    }

    return summary;
  }

  // Get summary for the last 30 days (for heatmap)
  Future<List<Map<String, dynamic>>> getThirtyDaySummary() async {
    final now = DateTime.now();
    // Start from 29 days ago to include today (30 days total)
    final startOfPeriod = now.subtract(const Duration(days: 29));
    final startOfPeriodMidnight = DateTime(
      startOfPeriod.year,
      startOfPeriod.month,
      startOfPeriod.day,
    );
    final endOfPeriod = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
    );

    final List<Map<String, dynamic>> summary = [];

    // Fetch all entries for user
    final entriesSnapshot = await _firestore
        .collection('time_entries')
        .where('userId', isEqualTo: userId)
        .get();

    final entries = entriesSnapshot.docs
            .map((doc) => TimeEntry.fromMap(doc.id, doc.data()))
            .where((entry) {
              return entry.startTime.millisecondsSinceEpoch >= 
                     startOfPeriodMidnight.millisecondsSinceEpoch &&
                     entry.startTime.millisecondsSinceEpoch <= 
                     endOfPeriod.millisecondsSinceEpoch;
            })
            .toList();

    // Generate last 30 days
    for (int i = 0; i < 30; i++) {
      final date = startOfPeriod.add(Duration(days: i));
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      int totalDuration = 0;
      for (var entry in entries) {
        if (entry.startTime.isAfter(
              startOfDay.subtract(const Duration(seconds: 1)),
            ) &&
            entry.startTime.isBefore(endOfDay.add(const Duration(seconds: 1)))) {
          totalDuration += entry.duration;
        }
      }

      summary.add({
        'date': date,
        'duration': totalDuration, // in seconds
        'hours': (totalDuration / 3600),
      });
    }

    return summary;
  }

  // Get hourly productivity for a specific day
  Future<List<double>> getHourlyProductivity(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final snapshot = await _firestore
        .collection('time_entries')
        .where('userId', isEqualTo: userId)
        .get();

    List<double> hourlyBuckets = List.filled(24, 0.0);

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final startTime = DateTime.fromMillisecondsSinceEpoch(
        data['startTime'] ?? 0,
      );
      final duration = (data['duration'] ?? 0) as int;

      // Double check range
      if (startTime.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
          startTime.isBefore(endOfDay.add(const Duration(seconds: 1)))) {
        int hour = startTime.hour;
        hourlyBuckets[hour] += duration / 60.0; // In minutes
      }
    }

    return hourlyBuckets;
  }

  // Get filtered entries for the reports screen
  Stream<List<TimeEntry>> getFilteredEntries({
    String? query,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    // Only filter by userId in Firestore to avoid index issues
    Query<Map<String, dynamic>> queryRef = _firestore
        .collection('time_entries')
        .where('userId', isEqualTo: userId);

    return queryRef.snapshots().map((snapshot) {
      var entries = snapshot.docs
          .map((doc) => TimeEntry.fromMap(doc.id, doc.data()))
          .toList();

      // Client-side filtering
      
      // Range filter
      if (startDate != null) {
        final s = DateTime(startDate.year, startDate.month, startDate.day);
        entries = entries.where((e) => 
            e.startTime.millisecondsSinceEpoch >= s.millisecondsSinceEpoch
        ).toList();
      }
      
      if (endDate != null) {
        final endOfDay = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
        );
        entries = entries.where((e) => 
            e.startTime.millisecondsSinceEpoch <= endOfDay.millisecondsSinceEpoch
        ).toList();
      }

      // Category filter
      if (category != null && category != 'All') {
        entries = entries.where((e) => e.category == category).toList();
      }

      // Text query filter
      if (query != null && query.isNotEmpty) {
        entries = entries
            .where(
              (e) => e.taskTitle.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }

      // Sort by start time
      entries.sort((a, b) => b.startTime.compareTo(a.startTime));
      return entries;
    });
  }

  // Log a Pomodoro session
  Future<void> logPomodoroSession(
    String taskId,
    String taskTitle,
    String category,
    int durationSeconds,
  ) async {
    await logTimeEntry(taskId, taskTitle, category, durationSeconds);
  }

  // Generic log time entry
  Future<void> logTimeEntry(
    String taskId,
    String taskTitle,
    String category,
    int durationSeconds,
  ) async {
    await _firestore.collection('time_entries').add({
      'userId': userId,
      'taskId': taskId,
      'taskTitle': taskTitle,
      'startTime': DateTime.now()
          .subtract(Duration(seconds: durationSeconds))
          .millisecondsSinceEpoch,
      'endTime': DateTime.now().millisecondsSinceEpoch,
      'duration': durationSeconds,
      'category': category,
      'isRunning': false,
      'source': 'manual_log',
    });
  }

  // ========== EXPORT ==========

  Future<String> exportToCSV() async {
    final snapshot = await _firestore
        .collection('time_entries')
        .where('userId', isEqualTo: userId)
        .get();

    List<List<dynamic>> rows = [];

    // Header
    rows.add([
      'Date',
      'Task',
      'Category',
      'Start Time',
      'End Time',
      'Duration (sec)',
      'Duration (min)',
    ]);

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final startTime = DateTime.fromMillisecondsSinceEpoch(
        data['startTime'] ?? 0,
      );
      final endTime = data['endTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['endTime'])
          : null;
      final duration = data['duration'] ?? 0;

      rows.add([
        startTime.toIso8601String().split('T')[0],
        data['taskTitle'] ?? '',
        data['category'] ?? '',
        startTime.toIso8601String(),
        endTime?.toIso8601String() ?? 'Running',
        duration,
        (duration / 60).toStringAsFixed(2),
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/timetracker_export_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    await file.writeAsString(csvData);
    return file.path;
  }
}
