/// ผลลัพธ์แบบแบ่งหน้าจาก backend: { data, total, page, limit, totalPages }
class PagedResult<T> {
  const PagedResult({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.total,
  });

  final List<T> items;
  final int page;
  final int totalPages;
  final int total;

  bool get hasMore => page < totalPages;

  static PagedResult<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> item) parseItem,
  ) {
    final data = json['data'];
    if (data is! List) {
      throw const FormatException('Paginated response has no data list');
    }
    return PagedResult<T>(
      items: [
        for (final item in data)
          if (item is Map<String, dynamic>) parseItem(item),
      ],
      page: _toInt(json['page']) ?? 1,
      totalPages: _toInt(json['totalPages']) ?? 1,
      total: _toInt(json['total']) ?? data.length,
    );
  }

  static int? _toInt(Object? value) => switch (value) {
    final int number => number,
    final num number => number.toInt(),
    final String text => int.tryParse(text),
    _ => null,
  };
}
