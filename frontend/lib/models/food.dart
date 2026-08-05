class Food {
  final String idfoods;
  final String name;
  final String category;
  final String description;
  final String filePathImage;

  Food({
    required this.idfoods,
    required this.name,
    required this.category,
    required this.description,
    required this.filePathImage,
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
    );
  }
}