/// คะแนนดาว + ความคิดเห็นของ event หนึ่งรายการ
class BannerRating {
  const BannerRating({
    required this.id,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.userName,
    this.userAvatarUrl,
  });

  final String id;
  final int rating;
  final String comment;
  final DateTime? createdAt;
  final String userName;
  final String? userAvatarUrl;

  factory BannerRating.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? const {};
    return BannerRating(
      id: json['id'].toString(),
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String? ?? '',
      createdAt: DateTime.tryParse(
        json['createdAt'] as String? ?? '',
      )?.toLocal(),
      userName: user['displayName'] as String? ?? 'ผู้ใช้',
      userAvatarUrl: user['avatarUrl'] as String?,
    );
  }
}

/// คะแนนเฉลี่ยของ event พร้อมความคิดเห็นล่าสุด
class BannerRatingSummary {
  const BannerRatingSummary({
    this.average = 0,
    this.count = 0,
    this.ratings = const [],
  });

  final double average;
  final int count;
  final List<BannerRating> ratings;

  factory BannerRatingSummary.fromJson(Map<String, dynamic> json) {
    return BannerRatingSummary(
      average: (json['average'] as num?)?.toDouble() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
      ratings: (json['ratings'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(BannerRating.fromJson)
          .toList(growable: false),
    );
  }
}
