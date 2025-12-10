import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task.dart';
import '../models/time_entry.dart';

class TimeTrackerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId => _auth.currentUser?.uid ?? '';

  // ========== TASK OPERATIONS ==========

  // Create a new task
  Future<void> createTask(
    String title,
    String description,
    String category,
    String color,
  ) async {
    await _firestore.collection('tasks').add({
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
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
          // Sort in memory to avoid composite index requirement
          tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return tasks;
        });
  }

  // Update task
  Future<void> updateTask(
    String taskId,
    String title,
    String description,
    String category,
  ) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'title': title,
      'description': description,
      'category': category,
    });
  }

  // Delete task (soft delete)
  Future<void> deleteTask(String taskId) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'isActive': false,
    });
  }

  // ========== TIME ENTRY OPERATIONS ==========

  // Start timer for a task
  Future<String> startTimer(
    String taskId,
    String taskTitle,
    String category,
  ) async {
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

    for (var doc in runningTimers.docs) {
      await stopTimer(doc.id);
    }
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

    return _firestore
        .collection('time_entries')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final entries = snapshot.docs
              .map((doc) => TimeEntry.fromMap(doc.id, doc.data()))
              .where((entry) {
                return entry.startTime.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
                       entry.startTime.isBefore(endOfDay.add(const Duration(seconds: 1)));
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
      final startTime = DateTime.fromMillisecondsSinceEpoch(data['startTime'] ?? 0);
      
      // Filter by date range in memory
      if (startTime.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
          startTime.isBefore(endOfDay.add(const Duration(seconds: 1)))) {
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
    final List<Map<String, dynamic>> summary = [];
    
    // Fetch all time entries for the user once
    final allEntries = await _firestore
        .collection('time_entries')
        .where('userId', isEqualTo: userId)
        .get();

    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      int totalDuration = 0;
      for (var doc in allEntries.docs) {
        final data = doc.data();
        final startTime = DateTime.fromMillisecondsSinceEpoch(data['startTime'] ?? 0);
        
        // Filter by date range in memory
        if (startTime.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
            startTime.isBefore(endOfDay.add(const Duration(seconds: 1)))) {
          totalDuration += (data['duration'] ?? 0) as int;
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
}
