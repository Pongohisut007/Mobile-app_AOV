class Food {
  final String idfoods;
  final String name;
  final String category;
  final String description;
  final String filePathImage;

  final int? preparationMinutes;
  final int? cookingMinutes;
  final int? servingCount;
  final String? difficulty;

  Food({
    required this.idfoods,
    required this.name,
    required this.category,
    required this.description,
    required this.filePathImage,
    this.preparationMinutes,
    this.cookingMinutes,
    this.servingCount,
    this.difficulty,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    // recipe หนึ่งอันมีได้หลาย category ที่นี่ใช้อันแรกมาโชว์บนการ์ด
    final categories = json['categories'] as List<dynamic>?;
    final firstCategory = (categories != null && categories.isNotEmpty)
        ? categories.first as Map<String, dynamic>
        : null;

    return Food(
      idfoods: json['id'] as String,
      name: json['title'] as String,
      category: firstCategory?['name'] as String? ?? '',
      description: json['shortDescription'] as String? ?? '',
      filePathImage: json['coverImageUrl'] as String? ?? '',
      preparationMinutes: _toInt(json['preparationMinutes']),
      cookingMinutes: _toInt(json['cookingMinutes']),
      servingCount: _toInt(json['servingCount']),
      difficulty: json['difficulty'] as String?,
    );
  }

  // numeric ที่ส่งมาจาก API อาจมาเป็น int หรือ String ก็ได้
  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}