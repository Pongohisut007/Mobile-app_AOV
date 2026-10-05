import 'package:flutter/widgets.dart';

class Category {
  final String id;

  /// ชื่อภาษาไทย (ชื่อหลัก)
  final String name;

  /// ชื่อภาษาอังกฤษ null = ยังไม่ได้ตั้ง ใช้ชื่อไทยแทน
  final String? nameEn;
  final String slug;
  final String? description;
  final String? imageUrl;
  final bool isActive;
  final int sortOrder;

  Category({
    required this.id,
    required this.name,
    this.nameEn,
    required this.slug,
    this.description,
    this.imageUrl,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      nameEn: _optionalText(json['nameEn']),
      slug: json['slug'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      sortOrder: _toInt(json['sortOrder']) ?? 0,
    );
  }

  /// หมวดที่ฝังมากับสูตร (recipe.categories) อ่านแบบไม่เข้มงวด ขาดอะไรก็ใช้ค่าว่าง
  factory Category.fromEmbeddedJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameEn: _optionalText(json['nameEn']),
      slug: json['slug'] as String? ?? '',
    );
  }

  /// ชื่อตามภาษา: อังกฤษใช้ nameEn ถ้ามี นอกนั้นใช้ชื่อไทย
  String nameFor(Locale locale) =>
      locale.languageCode == 'en' && nameEn != null ? nameEn! : name;

  /// ชื่อตามภาษาที่แอปใช้อยู่
  String displayName(BuildContext context) =>
      nameFor(Localizations.localeOf(context));

  /// ตรงกับคำค้นหาด้วยชื่อภาษาใดก็ได้
  bool matches(String query) {
    final q = query.toLowerCase();
    return name.toLowerCase().contains(q) ||
        (nameEn?.toLowerCase().contains(q) ?? false);
  }

  static String? _optionalText(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
