/// แบนเนอร์ด้านบนของหน้า Home (กดแล้วเปิดหน้ารายละเอียด event)
class BannerItem {
  const BannerItem({
    required this.id,
    required this.imageUrl,
    this.title = '',
    this.description = '',
    this.startDate,
    this.endDate,
  });

  final String id;
  final String imageUrl;
  final String title;
  final String description;
  final DateTime? startDate;
  final DateTime? endDate;

  factory BannerItem.fromJson(
    Map<String, dynamic> json, {
    required String apiBaseUrl,
  }) {
    return BannerItem(
      id: json['id'].toString(),
      imageUrl: _resolveUrl(json['imageUrl'] ?? json['image_url'], apiBaseUrl),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      startDate: _parseDate(json['startDate'] ?? json['start_date']),
      endDate: _parseDate(json['endDate'] ?? json['end_date']),
    );
  }

  /// รูปที่เก็บเป็น path สั้น ๆ (เช่น /uploads/images/a.jpg) ต้องต่อ base url ให้ครบก่อน
  static String _resolveUrl(Object? value, String apiBaseUrl) {
    if (value is! String || value.trim().isEmpty) return '';
    final uri = Uri.parse(value);
    if (uri.hasScheme) return uri.toString();

    final base = apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base${value.startsWith('/') ? value : '/$value'}';
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
