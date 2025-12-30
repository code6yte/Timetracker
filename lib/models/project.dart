class Project {
  final String id;
  final String userId;
  final String name;
  final String description;
  final String color;
  final int createdAt;

  Project({
    required this.id,
    required this.userId,
    required this.name,
    this.description = '',
    required this.color,
    required this.createdAt,
  });

  factory Project.fromMap(String id, Map<String, dynamic> data) {
    return Project(
      id: id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      color: data['color'] ?? '#FFFFFF',
      createdAt: data['createdAt'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      'color': color,
      'createdAt': createdAt
    };
  }
}
