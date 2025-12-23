class Project {
  final String id;
  final String name;
  final String color;
  final int createdAt;

  Project({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
  });

  factory Project.fromMap(String id, Map<String, dynamic> data) {
    return Project(
      id: id,
      name: data['name'] ?? '',
      color: data['color'] ?? '#FFFFFF',
      createdAt: data['createdAt'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'color': color, 'createdAt': createdAt};
  }
}
