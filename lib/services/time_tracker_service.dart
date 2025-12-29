import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import 'dart:io';
import '../models/task.dart';
import '../models/time_entry.dart';
import '../models/category.dart';
import '../models/project.dart';
import 'local_data_service.dart';

class TimeTrackerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalDataService _localData = LocalDataService();

  // Singleton
  static final TimeTrackerService _instance = TimeTrackerService._internal();
  factory TimeTrackerService() => _instance;
  TimeTrackerService._internal() {
    // Initialize sync when service is created (or on first access)
    // We can also trigger this manually on auth state change
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _startSync();
      } else {
        _stopSync();
      }
    });
  }

  StreamSubscription? _projectSub;
  StreamSubscription? _taskSub;
  StreamSubscription? _entrySub;

  String get userId => _auth.currentUser?.uid ?? '';

  void _startSync() {
    if (userId.isEmpty) return;

    // Sync Projects
    _projectSub?.cancel();
    _projectSub = _firestore
        .collection('projects')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      final projects = snapshot.docs
          .map((doc) => Project.fromMap(doc.id, doc.data()))
          .toList();
      _localData.updateProjects(projects);
    });

    // Sync Tasks
    _taskSub?.cancel();
    _taskSub = _firestore
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        // We sync ALL tasks (even inactive) to local DB so we have a full history if needed
        .snapshots()
        .listen((snapshot) {
      final tasks = snapshot.docs
          .map((doc) => Task.fromMap(doc.id, doc.data()))
          .toList();
      _localData.updateTasks(tasks);
    });

    // Sync Time Entries (The heavy one)
    _entrySub?.cancel();
    _entrySub = _firestore
        .collection('time_entries')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      final entries = snapshot.docs
          .map((doc) => TimeEntry.fromMap(doc.id, doc.data()))
          .toList();
      _localData.updateTimeEntries(entries);
    });
  }

  void _stopSync() {
    _projectSub?.cancel();
    _taskSub?.cancel();
    _entrySub?.cancel();
    _localData.clearAll();
  }

  // ========== PROJECT OPERATIONS ==========

  Future<void> createProject(String name, String color) async {
    await _firestore.collection('projects').add({
      'userId': userId,
      'name': name,
      'color': color,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Stream<List<Project>> getProjects() {
    // Return stream from Hive for instant load
    return Hive.box('projects').watch().map((_) => _localData.getProjects()).startWith(_localData.getProjects());
  }

  Future<void> deleteProject(String id) async {
    await _firestore.collection('projects').doc(id).delete();
    await _localData.deleteProject(id); // Optimistic update
  }

  Future<void> updateProject(String id, String name, String color) async {
    await _firestore.collection('projects').doc(id).update({
      'name': name,
      'color': color,
    });
    // Optimistic update logic could go here, but listener usually catches it fast enough
  }

  Stream<List<Category>> getCategories() {
    // Shim using Projects from Hive
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
    // This one is light, keep as is or cache in settings box
    return _firestore.collection('user_settings').doc(userId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return 8 * 3600;
      return (snapshot.data()?['dailyGoal'] ?? 8 * 3600) as int;
    });
  }

  // ========== TASK OPERATIONS ==========

  Future<void> createTask(
    String title,
    String description,
    String projectId,
    String projectName,
    String color,
  ) async {
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

  // Get active tasks from Hive
  Stream<List<Task>> getTasks() {
    return Hive.box('tasks').watch().map((_) {
      final tasks = _localData.getTasks().where((t) => t.isActive).toList();
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tasks;
    }).startWith(
        _localData.getTasks().where((t) => t.isActive).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt))
    );
  }

  Stream<List<Task>> getTasksByProject(String projectId) {
    return Hive.box('tasks').watch().map((_) {
      final tasks = _localData.getTasks()
          .where((t) => t.projectId == projectId && t.isActive)
          .toList();
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tasks;
    }).startWith(
        _localData.getTasks()
          .where((t) => t.projectId == projectId && t.isActive)
          .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt))
    );
  }

  Stream<List<Task>> getInboxTasks() {
    return Hive.box('tasks').watch().map((_) {
      final tasks = _localData.getTasks()
          .where((t) => (t.projectId.isEmpty) && t.isActive)
          .toList();
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tasks;
    }).startWith(
        _localData.getTasks()
          .where((t) => (t.projectId.isEmpty) && t.isActive)
          .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt))
    );
  }

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

  Future<void> deleteTask(String taskId) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'isActive': false,
    });
  }

  Future<void> undoDeleteTask(String taskId) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'isActive': true,
    });
  }

  // ========== TIME ENTRY OPERATIONS ==========

  Future<String> startTimer(
    String taskId,
    String taskTitle,
    String category, {
    int? expectedDuration,
    String source = 'manual',
  }) async {
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

  Future<bool> hasRunningTimer() async {
    // Keep this check against Firestore to ensure accuracy across devices
    final snapshot = await _firestore
        .collection('time_entries')
        .where('userId', isEqualTo: userId)
        .where('isRunning', isEqualTo: true)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Stream<TimeEntry?> getRunningTimer() {
    // This needs real-time accuracy, keep Firestore stream or use filtered Hive stream
    // Using Hive stream allows for offline support
    return Hive.box('time_entries').watch().map((_) {
      final entries = _localData.getTimeEntries().where((e) => e.isRunning).toList();
      return entries.isNotEmpty ? entries.first : null;
    }).startWith(
        _localData.getTimeEntries().where((e) => e.isRunning).firstOrNull
    );
  }

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

    // Optimized: Read from Hive instead of Firestore
    return Hive.box('time_entries').watch().map((_) {
      return _filterTimeEntries(startOfDay, endOfDay);
    }).startWith(_filterTimeEntries(startOfDay, endOfDay));
  }

  List<TimeEntry> _filterTimeEntries(DateTime start, DateTime end) {
    final entries = _localData.getTimeEntries().where((entry) {
        return entry.startTime.millisecondsSinceEpoch >=
                start.millisecondsSinceEpoch &&
            entry.startTime.millisecondsSinceEpoch <=
                end.millisecondsSinceEpoch;
      })
      .toList();
    entries.sort((a, b) => b.startTime.compareTo(a.startTime));
    return entries;
  }

  Stream<List<TimeEntry>> getTodayEntries() {
    final now = DateTime.now();
    return getTimeEntries(now, now);
  }

  Stream<List<TimeEntry>> getWeekEntries() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return getTimeEntries(startOfWeek, now);
  }

  // ========== ANALYTICS (Optimized to use Local Data) ==========

  Future<Map<String, int>> getCategoryBreakdown(DateTime start, DateTime end) async {
    final entries = _localData.getTimeEntries();
    final Map<String, int> categoryTime = {};

    final startMs = start.millisecondsSinceEpoch;
    final endMs = end.millisecondsSinceEpoch;

    for (var data in entries) {
      if (data.startTime.millisecondsSinceEpoch >= startMs && 
          data.startTime.millisecondsSinceEpoch <= endMs) {
        
        // Handle entries that might span across the range boundary (simplified: just check start time)
        // For strict reporting, we should clip duration, but for now strict start time inclusion is fine.
        final category = data.category.isEmpty ? 'Uncategorized' : data.category;
        final duration = data.duration;
        categoryTime[category] = (categoryTime[category] ?? 0) + duration;
      }
    }
    return categoryTime;
  }

  Future<List<Map<String, dynamic>>> getDailyBreakdown(DateTime start, DateTime end) async {
    final entries = _localData.getTimeEntries();
    final List<Map<String, dynamic>> dailyData = [];

    // Normalize dates to midnight
    DateTime current = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);

    while (current.isBefore(last) || current.isAtSameMomentAs(last)) {
      final nextDay = current.add(const Duration(days: 1));
      final currentMs = current.millisecondsSinceEpoch;
      final nextDayMs = nextDay.millisecondsSinceEpoch;

      int totalDuration = 0;
      for (var e in entries) {
        // Simple check: entry starts on this day
        if (e.startTime.millisecondsSinceEpoch >= currentMs && 
            e.startTime.millisecondsSinceEpoch < nextDayMs) {
          totalDuration += e.duration;
        }
      }

      dailyData.add({
        'date': current,
        'duration': totalDuration,
        'hours': totalDuration / 3600.0,
      });

      current = nextDay;
    }
    return dailyData;
  }

  Future<Map<String, int>> getTodayTimeByCategory() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final entries = _localData.getTimeEntries();

    final Map<String, int> categoryTime = {};

    for (var data in entries) {
      if (data.startTime.millisecondsSinceEpoch >= startOfDay.millisecondsSinceEpoch && 
          data.startTime.millisecondsSinceEpoch <= endOfDay.millisecondsSinceEpoch) {
          
        final category = data.category;
        final duration = data.duration;
        categoryTime[category] = (categoryTime[category] ?? 0) + duration;
      }
    }

    return categoryTime;
  }

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

    // Use local data
    final weekEntries = _localData.getTimeEntries().where((entry) {
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

  Future<List<Map<String, dynamic>>> getThirtyDaySummary() async {
    final now = DateTime.now();
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

    // Use local data
    final entries = _localData.getTimeEntries().where((entry) {
              return entry.startTime.millisecondsSinceEpoch >= 
                     startOfPeriodMidnight.millisecondsSinceEpoch &&
                     entry.startTime.millisecondsSinceEpoch <= 
                     endOfPeriod.millisecondsSinceEpoch;
            })
            .toList();

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
        'duration': totalDuration,
        'hours': (totalDuration / 3600),
      });
    }

    return summary;
  }

  Future<List<double>> getHourlyProductivity(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final entries = _localData.getTimeEntries();

    List<double> hourlyBuckets = List.filled(24, 0.0);

    for (var entry in entries) {
      final startTime = entry.startTime;
      final duration = entry.duration;

      if (startTime.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
          startTime.isBefore(endOfDay.add(const Duration(seconds: 1)))) {
        int hour = startTime.hour;
        hourlyBuckets[hour] += duration / 60.0;
      }
    }

    return hourlyBuckets;
  }

  // Optimize: Use Hive watch()
  Stream<List<TimeEntry>> getFilteredEntries({
    String? query,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return Hive.box('time_entries').watch().map((_) {
      return _getFilteredEntriesList(query: query, category: category, startDate: startDate, endDate: endDate);
    }).startWith(
      _getFilteredEntriesList(query: query, category: category, startDate: startDate, endDate: endDate)
    );
  }

  List<TimeEntry> _getFilteredEntriesList({
    String? query,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    var entries = _localData.getTimeEntries();

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

    if (category != null && category != 'All') {
      entries = entries.where((e) => e.category == category).toList();
    }

    if (query != null && query.isNotEmpty) {
      entries = entries
          .where(
            (e) => e.taskTitle.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }

    entries.sort((a, b) => b.startTime.compareTo(a.startTime));
    return entries;
  }

  Future<void> logPomodoroSession(
    String taskId,
    String taskTitle,
    String category,
    int durationSeconds,
  ) async {
    await logTimeEntry(taskId, taskTitle, category, durationSeconds);
  }

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
    // Export from local data
    final entries = _localData.getTimeEntries();

    List<List<dynamic>> rows = [];

    rows.add([
      'Date',
      'Task',
      'Category',
      'Start Time',
      'End Time',
      'Duration (sec)',
      'Duration (min)',
    ]);

    for (var entry in entries) {
      rows.add([
        entry.startTime.toIso8601String().split('T')[0],
        entry.taskTitle,
        entry.category,
        entry.startTime.toIso8601String(),
        entry.endTime?.toIso8601String() ?? 'Running',
        entry.duration,
        (entry.duration / 60).toStringAsFixed(2),
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

// Extension to help with stream starting value
extension StreamStartWith<T> on Stream<T> {
  Stream<T> startWith(T value) async* {
    yield value;
    yield* this;
  }
}

