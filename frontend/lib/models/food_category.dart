class FoodCategory {
  final String id;
  final DateTime createAt;
  final DateTime updateAt;
  final String slug;
  final String name;
  final String description;
  final String imageUrl;
  final bool isActive;
  final String sortOrder;

  FoodCategory({
    required this.id,
    required this.createAt,
    required this.updateAt,
    required this.slug,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.isActive,
    required this.sortOrder,
  });

  factory FoodCategory.fromJson(Map<String, dynamic> json) {
    return FoodCategory(
      id: json['id']?.toString() ?? '',
      createAt: DateTime.tryParse(json['create_at']?.toString() ?? '') ??
          DateTime.now(),
      updateAt: DateTime.tryParse(json['update_at']?.toString() ?? '') ??
          DateTime.now(),
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      isActive: json['isActive'] ?? false,
      sortOrder: json['sortOrder']?.toString() ?? '',
    );
  }
}