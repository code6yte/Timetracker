class Category {
  final String id;
  final String userId;
  final String name;
  final String color;
  final String icon;

  Category({
    required this.id,
    required this.userId,
    required this.name,
    this.color = '#2196F3',
    this.icon = 'category',
  });

  Map<String, dynamic> toMap() {
    return {'userId': userId, 'name': name, 'color': color, 'icon': icon};
  }

  factory Category.fromMap(String id, Map<String, dynamic> map) {
    return Category(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      color: map['color'] ?? '#2196F3',
      icon: map['icon'] ?? 'category',
    );
  }
}
