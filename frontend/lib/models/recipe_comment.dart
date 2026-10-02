class RecipeComment {
  const RecipeComment({
    required this.id,
    required this.comment,
    required this.createdAt,
    required this.userName,
    this.userAvatarUrl,
  });

  final String id;
  final String comment;
  final DateTime? createdAt;
  final String userName;
  final String? userAvatarUrl;

  factory RecipeComment.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? const {};
    return RecipeComment(
      id: json['id'].toString(),
      comment: json['comment'] as String? ?? '',
      createdAt: DateTime.tryParse(
        json['createdAt'] as String? ?? '',
      )?.toLocal(),
      userName: user['displayName'] as String? ?? 'ผู้ใช้',
      userAvatarUrl: user['avatarUrl'] as String?,
    );
  }
}

class RecipeCommentPage {
  const RecipeCommentPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<RecipeComment> items;
  final int total;
  final int page;
  final int limit;

  bool get hasMore => page * limit < total;

  factory RecipeCommentPage.fromJson(Map<String, dynamic> json) {
    return RecipeCommentPage(
      items: (json['items'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(RecipeComment.fromJson)
          .toList(growable: false),
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 3,
    );
  }
}