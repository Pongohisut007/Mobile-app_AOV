import 'package:flutter/widgets.dart';
import 'package:flutter_application_1/models/category.dart';

class RecipeSummary {
  const RecipeSummary({
    required this.id,
    required this.title,
    this.titleEn,
    required this.description,
    required this.coverImageUrl,
    required this.price,
    required this.status,
    required this.type,
    required this.categories,
  });

  final String id;
  final String title;

  /// ชื่อภาษาอังกฤษ null = ใช้ชื่อไทยแทน
  final String? titleEn;
  final String description;
  final String? coverImageUrl;
  final double price;
  final String status;
  final String type;
  final List<Category> categories;

  factory RecipeSummary.fromJson(
    Map<String, dynamic> json, {
    required String apiBaseUrl,
  }) {
    final categories = json['categories'];

    return RecipeSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      titleEn: _optionalText(json['titleEn']),
      description: json['shortDescription'] as String? ?? '',
      coverImageUrl: _resolveUrl(json['coverImageUrl'], apiBaseUrl),
      price: double.tryParse(json['price'].toString()) ?? 0,
      status: json['status'] as String? ?? 'draft',
      type: json['type'] as String,
      categories: categories is List
          ? categories
                .whereType<Map<String, dynamic>>()
                .map(Category.fromEmbeddedJson)
                .where((category) => category.name.isNotEmpty)
                .toList(growable: false)
          : const [],
    );
  }

  /// ชื่อตามภาษาที่แอปใช้อยู่
  String displayTitle(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'en' && titleEn != null
      ? titleEn!
      : title;

  static String? _optionalText(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;

  static String? _resolveUrl(Object? value, String apiBaseUrl) {
    if (value is! String || value.trim().isEmpty) return null;
    final uri = Uri.parse(value);
    if (uri.hasScheme) return uri.toString();

    final base = apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base${value.startsWith('/') ? value : '/$value'}';
  }
}
