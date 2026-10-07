import 'package:flutter/widgets.dart';
import 'package:flutter_application_1/l10n/l10n.dart';

enum AppNotificationType {
  recipePurchased('recipe_purchased'),
  recipeModerated('recipe_moderated'),
  recipeReviewed('recipe_reviewed'),
  recipeCommented('recipe_commented'),
  // backend เพิ่มประเภทใหม่แต่แอปยังเป็นรุ่นเก่า: ยังแสดงในรายการได้ ไม่พัง
  unknown('');

  const AppNotificationType(this.value);

  final String value;

  static AppNotificationType parse(Object? value) => values.firstWhere(
    (type) => type.value == value && type != unknown,
    orElse: () => unknown,
  );
}

/// หนึ่งรายการในกล่องแจ้งเตือน (GET /notifications)
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.createdAt,
    this.readAt,
    this.actorName,
    this.actorAvatarUrl,
    this.recipeId,
    this.recipeTitle,
    this.recipeTitleEn,
    this.recipeCoverUrl,
    this.status,
    this.rating,
    this.excerpt,
  });

  final String id;
  final AppNotificationType type;
  final DateTime createdAt;
  final DateTime? readAt;

  /// คนที่ทำ (ซื้อ/รีวิว/คอมเมนต์) null = ทีมงาน หรือบัญชีถูกลบไปแล้ว
  final String? actorName;
  final String? actorAvatarUrl;

  /// null = สูตรถูกลบไปแล้ว
  final String? recipeId;
  final String? recipeTitle;
  final String? recipeTitleEn;
  final String? recipeCoverUrl;

  /// recipeModerated: 'hidden' | 'rejected'
  final String? status;

  /// recipeReviewed
  final int? rating;

  /// ข้อความรีวิว/คอมเมนต์แบบตัดสั้น
  final String? excerpt;

  bool get isRead => readAt != null;

  AppNotification markedRead() => AppNotification(
    id: id,
    type: type,
    createdAt: createdAt,
    readAt: readAt ?? DateTime.now(),
    actorName: actorName,
    actorAvatarUrl: actorAvatarUrl,
    recipeId: recipeId,
    recipeTitle: recipeTitle,
    recipeTitleEn: recipeTitleEn,
    recipeCoverUrl: recipeCoverUrl,
    status: status,
    rating: rating,
    excerpt: excerpt,
  );

  factory AppNotification.fromJson(
    Map<String, dynamic> json, {
    required String apiBaseUrl,
  }) {
    final actor = json['actor'];
    final recipe = json['recipe'];
    final data = json['data'];
    final actorMap = actor is Map<String, dynamic> ? actor : null;
    final recipeMap = recipe is Map<String, dynamic> ? recipe : null;
    final dataMap = data is Map<String, dynamic> ? data : const {};

    return AppNotification(
      id: json['id'] as String,
      type: AppNotificationType.parse(json['type']),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      readAt: DateTime.tryParse(json['readAt'] as String? ?? '')?.toLocal(),
      actorName: _text(actorMap?['displayName']),
      actorAvatarUrl: _resolveUrl(actorMap?['avatarUrl'], apiBaseUrl),
      recipeId: _text(recipeMap?['id']),
      recipeTitle: _text(recipeMap?['title']),
      recipeTitleEn: _text(recipeMap?['titleEn']),
      recipeCoverUrl: _resolveUrl(recipeMap?['coverImageUrl'], apiBaseUrl),
      status: _text(dataMap['status']),
      rating: (dataMap['rating'] as num?)?.toInt(),
      excerpt: _text(dataMap['excerpt']),
    );
  }

  /// ชื่อสูตรตามภาษา (อังกฤษไม่มีชื่อ = ใช้ชื่อไทย)
  String recipeName(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    return (english ? recipeTitleEn : null) ??
        recipeTitle ??
        context.l10n.notificationDeletedRecipe;
  }

  /// ข้อความหลักของรายการ ประกอบในแอปตามภาษาที่ผู้ใช้เลือก
  String message(BuildContext context) {
    final l10n = context.l10n;
    final recipe = recipeName(context);
    final actor = actorName ?? l10n.notificationSomeone;
    return switch (type) {
      AppNotificationType.recipePurchased => l10n.notificationPurchased(
        actor,
        recipe,
      ),
      AppNotificationType.recipeModerated =>
        status == 'rejected'
            ? l10n.notificationRejected(recipe)
            : l10n.notificationHidden(recipe),
      AppNotificationType.recipeReviewed => l10n.notificationReviewed(
        actor,
        rating ?? 0,
        recipe,
      ),
      AppNotificationType.recipeCommented => l10n.notificationCommented(
        actor,
        recipe,
      ),
      AppNotificationType.unknown => l10n.notificationGeneric(recipe),
    };
  }

  static String? _text(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;

  // รูปที่ backend เก็บเป็น path สัมพัทธ์ ต้องเติม host ให้ก่อนถึงโหลดได้
  static String? _resolveUrl(Object? value, String apiBaseUrl) {
    if (value is! String || value.trim().isEmpty) return null;
    final uri = Uri.parse(value);
    if (uri.hasScheme) return uri.toString();
    final base = apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base${value.startsWith('/') ? value : '/$value'}';
  }
}

/// สวิตช์ push ในหน้าตั้งค่า (GET/PATCH /notifications/settings)
class NotificationSettings {
  const NotificationSettings({
    this.pushEnabled = true,
    this.sales = true,
    this.moderation = true,
    this.reviews = true,
    this.comments = true,
  });

  final bool pushEnabled;
  final bool sales;
  final bool moderation;
  final bool reviews;
  final bool comments;

  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      NotificationSettings(
        pushEnabled: json['pushEnabled'] as bool? ?? true,
        sales: json['sales'] as bool? ?? true,
        moderation: json['moderation'] as bool? ?? true,
        reviews: json['reviews'] as bool? ?? true,
        comments: json['comments'] as bool? ?? true,
      );

  Map<String, bool> toJson() => {
    'pushEnabled': pushEnabled,
    'sales': sales,
    'moderation': moderation,
    'reviews': reviews,
    'comments': comments,
  };

  NotificationSettings copyWith({
    bool? pushEnabled,
    bool? sales,
    bool? moderation,
    bool? reviews,
    bool? comments,
  }) => NotificationSettings(
    pushEnabled: pushEnabled ?? this.pushEnabled,
    sales: sales ?? this.sales,
    moderation: moderation ?? this.moderation,
    reviews: reviews ?? this.reviews,
    comments: comments ?? this.comments,
  );
}
