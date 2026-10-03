import 'package:flutter_application_1/models/recipe_step.dart';

class Food {
  final String idfoods;
  final String name;
  final String category;
  // ใช้ตอนแก้ไขสูตร (prefill หน้า CreateFoodcardPage)
  final String slug;
  final String? type;
  final String? status;
  final List<String> categoryIds;
  final String description;
  final String filePathImage;
  final bool showImgCommu;
  final double price;
  final int favoriteCount;
  final int reviewCount;
  final int commentCount;

  final int? preparationMinutes;
  final int? cookingMinutes;
  final int? servingCount;
  final String? difficulty;
  final List<RecipeStep> steps;

  // ผู้ชมเห็นขั้นตอนครบไหม (backend ส่งมาเฉพาะ GET /recipes/:id)
  // official ที่ยังไม่ซื้อจะเป็น false และได้มาแค่ขั้นตอน preview
  final bool canViewFullRecipe;

  // ข้อมูลเจ้าของ recipe (embed มาจาก backend)
  final String? creatorId;
  final String? creatorName;
  final String? creatorAvatar;

  // วันที่ publish (ใช้คำนวณว่า "โพสต์มานานแค่ไหนแล้ว")
  final DateTime? publishedAt;

  Food({
    required this.idfoods,
    required this.name,
    required this.category,
    this.slug = '',
    this.type,
    this.status,
    this.categoryIds = const [],
    required this.description,
    required this.filePathImage,
    this.showImgCommu = false,
    this.price = 0,
    this.favoriteCount = 0,
    this.reviewCount = 0,
    this.commentCount = 0,
    this.preparationMinutes,
    this.cookingMinutes,
    this.servingCount,
    this.difficulty,
    this.steps = const [],
    this.canViewFullRecipe = true,
    this.creatorId,
    this.creatorName,
    this.creatorAvatar,
    this.publishedAt,
  });

  factory Food.fromJson(
    Map<String, dynamic> json, {
    required String apiBaseUrl,
  }) {
    // recipe หนึ่งอันมีได้หลาย category ที่นี่ใช้อันแรกมาโชว์บนการ์ด
    final categories = json['categories'] as List<dynamic>?;
    final creator = json['creator'] as Map<String, dynamic>?;
    final firstCategory = (categories != null && categories.isNotEmpty)
        ? categories.first as Map<String, dynamic>
        : null;

    final sections = json['sections'] as List<dynamic>? ?? const [];
    final steps = <RecipeStep>[];
    for (final sectionValue in sections) {
      if (sectionValue is! Map<String, dynamic>) continue;
      final sectionId = sectionValue['id'] as String? ?? '';
      final sectionTitle = sectionValue['title'] as String? ?? 'ขั้นตอน';
      final sectionDescription = sectionValue['description'] as String? ?? '';
      final contents = sectionValue['contents'] as List<dynamic>? ?? const [];

      for (final contentValue in contents) {
        if (contentValue is! Map<String, dynamic>) continue;
        steps.add(
          RecipeStep.fromJson(
            contentValue,
            sectionId: sectionId,
            sectionTitle: sectionTitle,
            sectionDescription: sectionDescription,
          ),
        );
      }
    }

    return Food(
      idfoods: json['id'] as String,
      name: json['title'] as String,
      category: firstCategory?['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      type: json['type'] as String?,
      status: json['status'] as String?,
      categoryIds: [
        for (final value in categories ?? const [])
          if (value is Map<String, dynamic> && value['id'] is String)
            value['id'] as String,
      ],
      description: json['shortDescription'] as String? ?? '',
      filePathImage: json['coverImageUrl'] as String? ?? '',
      showImgCommu: json['showImgCommu'] as bool? ?? false,
      // backend ส่ง numeric ของ postgres มาเป็น string เช่น "129.00"
      price: _toDouble(json['price']),
      favoriteCount: _toInt(json['favoriteCount']) ?? 0,
      reviewCount: _toInt(json['reviewCount']) ?? 0,
      commentCount: _toInt(json['commentCount']) ?? 0,
      preparationMinutes: _toInt(json['preparationMinutes']),
      cookingMinutes: _toInt(json['cookingMinutes']),
      servingCount: _toInt(json['servingCount']),
      difficulty: json['difficulty'] as String?,
      steps: steps,
      canViewFullRecipe: json['canViewFullRecipe'] as bool? ?? true,
      creatorId: creator?['id'] as String?,
      creatorName: creator?['displayName'] as String?,
      creatorAvatar: _resolveAvatarUrl(creator?['avatarUrl'], apiBaseUrl),
      publishedAt: json['publishedAt'] == null
          ? null
          : DateTime.tryParse(json['publishedAt'] as String),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  // numeric ที่ส่งมาจาก API อาจมาเป็น int หรือ String ก็ได้
  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static String? _resolveAvatarUrl(Object? value, String apiBaseUrl) {
    if (value == null) return null;
    if (value is! String) {
      throw const FormatException('Profile field "avatarUrl" is invalid');
    }
    if (value.trim().isEmpty) return null;

    final uri = Uri.parse(value);
    if (uri.hasScheme) return uri.toString();

    final normalizedBaseUrl = apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final normalizedPath = value.startsWith('/') ? value : '/$value';
    return '$normalizedBaseUrl$normalizedPath';
  }
}
