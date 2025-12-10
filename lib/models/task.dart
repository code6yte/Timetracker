class Task {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;
  final String color;
  final DateTime createdAt;
  final bool isActive;

  Task({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    this.category = 'Work',
    this.color = '#2196F3',
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'color': color,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isActive': isActive,
    };
  }

  factory Task.fromMap(String id, Map<String, dynamic> map) {
    return Task(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Work',
      color: map['color'] ?? '#2196F3',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      isActive: map['isActive'] ?? true,
    );
  }
}
