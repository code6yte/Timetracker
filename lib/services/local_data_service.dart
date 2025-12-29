import 'package:hive_flutter/hive_flutter.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/time_entry.dart';

class LocalDataService {
  final Box _projectBox = Hive.box('projects');
  final Box _taskBox = Hive.box('tasks');
  final Box _entryBox = Hive.box('time_entries');

  // Singleton
  static final LocalDataService _instance = LocalDataService._internal();
  factory LocalDataService() => _instance;
  LocalDataService._internal();

  // Projects
  List<Project> getProjects() {
    return _projectBox.values.map((e) {
      final map = Map<String, dynamic>.from(e);
      return Project.fromMap(map['id'], map);
    }).toList();
  }

  Future<void> saveProject(Project project) async {
    final map = project.toMap();
    map['id'] = project.id; // Store ID inside map for easy retrieval
    await _projectBox.put(project.id, map);
  }

  Future<void> deleteProject(String id) async {
    await _projectBox.delete(id);
  }

  // Tasks
  List<Task> getTasks() {
    return _taskBox.values.map((e) {
      final map = Map<String, dynamic>.from(e);
      return Task.fromMap(map['id'], map);
    }).toList();
  }

  Future<void> saveTask(Task task) async {
    final map = task.toMap();
    map['id'] = task.id;
    await _taskBox.put(task.id, map);
  }

  Future<void> deleteTask(String id) async {
    await _taskBox.delete(id);
  }

  // Time Entries
  List<TimeEntry> getTimeEntries() {
    return _entryBox.values.map((e) {
      final map = Map<String, dynamic>.from(e);
      return TimeEntry.fromMap(map['id'], map);
    }).toList();
  }

  Future<void> saveTimeEntry(TimeEntry entry) async {
    final map = entry.toMap();
    map['id'] = entry.id;
    await _entryBox.put(entry.id, map);
  }

  Future<void> deleteTimeEntry(String id) async {
    await _entryBox.delete(id);
  }

  // Bulk Operations (for Sync)
  Future<void> updateProjects(List<Project> projects) async {
    final Map<String, Map<String, dynamic>> entries = {};
    for (var p in projects) {
      final map = p.toMap();
      map['id'] = p.id;
      entries[p.id] = map;
    }
    await _projectBox.putAll(entries);
  }

  Future<void> updateTasks(List<Task> tasks) async {
    final Map<String, Map<String, dynamic>> entries = {};
    for (var t in tasks) {
      final map = t.toMap();
      map['id'] = t.id;
      entries[t.id] = map;
    }
    await _taskBox.putAll(entries);
  }

  Future<void> updateTimeEntries(List<TimeEntry> timeEntries) async {
    final Map<String, Map<String, dynamic>> entries = {};
    for (var e in timeEntries) {
      final map = e.toMap();
      map['id'] = e.id;
      entries[e.id] = map;
    }
    await _entryBox.putAll(entries);
  }

  Future<void> clearAll() async {
    await _projectBox.clear();
    await _taskBox.clear();
    await _entryBox.clear();
  }
}
