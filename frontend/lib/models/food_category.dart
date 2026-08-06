class FoodCategory {
  final int id;
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
      id: json['id'] as int,
      createAt: DateTime.parse(json['create_at'] as String),
      updateAt: DateTime.parse(json['update_at'] as String),
      slug: json['slug'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      imageUrl: json['image_url'] as String,
      isActive: json['is_active'] as bool,
      sortOrder: json['sort_order'] as String,
    );
  }
}