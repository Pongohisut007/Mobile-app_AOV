/// คะแนนดาว + ความคิดเห็นของสูตรอาหาร หนึ่งรายการ (ตาราง reviews)
class RecipeReview {
  const RecipeReview({
    required this.id,
    required this.rating,
    required this.comment,
    this.tags = const [],
    required this.createdAt,
    required this.userName,
    this.userAvatarUrl,
  });

  final String id;
  final int rating;
  final String comment;

  /// key ของชิป "ชอบอะไรในสูตรนี้" ดู ReviewTag
  final List<String> tags;
  final DateTime? createdAt;
  final String userName;
  final String? userAvatarUrl;

  factory RecipeReview.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? const {};
    return RecipeReview(
      id: json['id'].toString(),
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String? ?? '',
      tags: (json['tags'] as List? ?? const []).whereType<String>().toList(
        growable: false,
      ),
      createdAt: DateTime.tryParse(
        json['createdAt'] as String? ?? '',
      )?.toLocal(),
      userName: user['displayName'] as String? ?? 'ผู้ใช้',
      userAvatarUrl: user['avatarUrl'] as String?,
    );
  }
}

/// คะแนนเฉลี่ยของสูตรพร้อมรีวิวล่าสุด
class RecipeReviewSummary {
  const RecipeReviewSummary({
    this.average = 0,
    this.count = 0,
    this.distribution = const {},
    this.reviews = const [],
  });

  final double average;
  final int count;

  /// จำนวนรีวิวของแต่ละดาว เช่น {5: 3, 4: 1}
  final Map<int, int> distribution;

  /// รีวิวล่าสุดไม่กี่อัน ที่เหลือดูในหน้ารีวิวทั้งหมด
  final List<RecipeReview> reviews;

  int countFor(int stars) => distribution[stars] ?? 0;

  factory RecipeReviewSummary.fromJson(Map<String, dynamic> json) {
    return RecipeReviewSummary(
      average: (json['average'] as num?)?.toDouble() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
      distribution: _parseDistribution(json['distribution']),
      reviews: (json['reviews'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(RecipeReview.fromJson)
          .toList(growable: false),
    );
  }

  /// backend ส่ง key เป็น string เช่น {"5": 3, "4": 1}
  static Map<int, int> _parseDistribution(Object? raw) {
    if (raw is! Map<String, dynamic>) return const {};
    final result = <int, int>{};
    for (final MapEntry(key: starKey, value: count) in raw.entries) {
      final stars = int.tryParse(starKey);
      if (stars == null || count is! num) continue;
      result[stars] = count.toInt();
    }
    return result;
  }
}

/// รีวิวของคนที่ล็อกอินอยู่ และสิทธิ์ว่าให้คะแนนได้ไหม (ต้องซื้อสูตรแล้ว)
class MyRecipeReview {
  const MyRecipeReview({required this.canReview, this.review});

  final bool canReview;

  /// ยังไม่เคยรีวิว = null
  final RecipeReview? review;

  factory MyRecipeReview.fromJson(Map<String, dynamic> json) {
    final review = json['review'];
    return MyRecipeReview(
      canReview: json['canReview'] as bool? ?? false,
      review: review is Map<String, dynamic>
          ? RecipeReview.fromJson(review)
          : null,
    );
  }
}

/// รีวิวหนึ่งหน้าสำหรับหน้ารีวิวทั้งหมด
class RecipeReviewPage {
  const RecipeReviewPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<RecipeReview> items;
  final int total;
  final int page;
  final int limit;

  bool get hasMore => page * limit < total;

  factory RecipeReviewPage.fromJson(Map<String, dynamic> json) {
    return RecipeReviewPage(
      items: (json['items'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(RecipeReview.fromJson)
          .toList(growable: false),
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
    );
  }
}
