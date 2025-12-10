class TimeEntry {
  final String id;
  final String userId;
  final String taskId;
  final String taskTitle;
  final DateTime startTime;
  final DateTime? endTime;
  final int duration; // in seconds
  final String category;
  final bool isRunning;

  TimeEntry({
    required this.id,
    required this.userId,
    required this.taskId,
    required this.taskTitle,
    required this.startTime,
    this.endTime,
    this.duration = 0,
    this.category = 'Work',
    this.isRunning = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'taskId': taskId,
      'taskTitle': taskTitle,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'duration': duration,
      'category': category,
      'isRunning': isRunning,
    };
  }

  factory TimeEntry.fromMap(String id, Map<String, dynamic> map) {
    return TimeEntry(
      id: id,
      userId: map['userId'] ?? '',
      taskId: map['taskId'] ?? '',
      taskTitle: map['taskTitle'] ?? '',
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime'] ?? 0),
      endTime: map['endTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endTime'])
          : null,
      duration: map['duration'] ?? 0,
      category: map['category'] ?? 'Work',
      isRunning: map['isRunning'] ?? false,
    );
  }

  TimeEntry copyWith({
    String? id,
    String? userId,
    String? taskId,
    String? taskTitle,
    DateTime? startTime,
    DateTime? endTime,
    int? duration,
    String? category,
    bool? isRunning,
  }) {
    return TimeEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      taskId: taskId ?? this.taskId,
      taskTitle: taskTitle ?? this.taskTitle,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      category: category ?? this.category,
      isRunning: isRunning ?? this.isRunning,
    );
  }
}
