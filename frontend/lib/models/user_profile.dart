import 'package:flutter_application_1/l10n/l10n.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    required this.role,
    required this.status,
    required this.recipeCount,
    required this.purchasedCount,
    required this.savedCount,
    required this.draftCount,
    required this.rating,
    this.reviewCount = 0,
    this.salesCount = 0,
    this.officialSavedCount = 0,
    this.communitySavedCount = 0,
    this.commentsReceivedCount = 0,
    this.reviewsWrittenCount = 0,
  });

  static const fallbackAvatarAsset = 'assets/images/Profile1.jpg';

  final String id;
  final String displayName;
  final String email;
  final String? avatarUrl;
  final String role;
  final String status;
  final int recipeCount;
  final int purchasedCount;
  final int savedCount;
  final int draftCount;

  /// ค่าเฉลี่ยรีวิวที่สูตรของคนนี้ได้รับ
  final double rating;

  // ตัวเลขผลงานบนหน้าโปรไฟล์ (แสดงตามบทบาท ดู ProfileStatsRow)
  /// จำนวนรีวิวที่สูตรของคนนี้ได้รับ
  final int reviewCount;

  /// จำนวนครั้งที่สูตรของคนนี้ถูกซื้อ
  final int salesCount;

  /// หัวใจจากคนอื่นบนสูตร official / community ของคนนี้
  final int officialSavedCount;
  final int communitySavedCount;

  /// ความคิดเห็นจากคนอื่นบนสูตร community ของคนนี้
  final int commentsReceivedCount;

  /// รีวิวที่คนนี้เขียนให้สูตรที่ซื้อมา
  final int reviewsWrittenCount;

  bool get isCreator => role == 'creator';

  factory UserProfile.guest() {
    // ชื่อ "ผู้เยี่ยมชม" แปลตอนแสดงผล (ดู [displayNameFor]) ไม่เก็บไว้ที่นี่
    // ไม่งั้นเปลี่ยนภาษาแล้วชื่อยังค้างเป็นภาษาเดิม
    return const UserProfile(
      id: '',
      displayName: '',
      email: '-',
      avatarUrl: null,
      role: 'guest',
      status: 'guest',
      recipeCount: 0,
      purchasedCount: 0,
      savedCount: 0,
      draftCount: 0,
      rating: 0,
    );
  }

  bool get isGuest => role == 'guest';

  /// ชื่อที่แสดง ผู้เยี่ยมชมใช้คำว่า "ผู้เยี่ยมชม" ตามภาษาปัจจุบัน
  String displayNameFor(AppLocalizations l10n) =>
      isGuest ? l10n.guest : displayName;

  String roleLabel(AppLocalizations l10n) => switch (role) {
    'creator' => l10n.roleCreator,
    'admin' => l10n.roleAdmin,
    _ => l10n.roleFoodLover,
  };

  factory UserProfile.fromJson(
    Map<String, dynamic> json, {
    required String apiBaseUrl,
  }) {
    final rawAvatarUrl = json['avatarUrl'];

    return UserProfile(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      status: json['status'] as String,
      recipeCount: (json['recipeCount'] as num).toInt(),
      purchasedCount: (json['purchasedCount'] as num).toInt(),
      savedCount: (json['savedCount'] as num).toInt(),
      draftCount: (json['draftCount'] as num).toInt(),
      rating: (json['rating'] as num).toDouble(),
      // backend เก่ายังไม่ส่งมา ให้เป็น 0 ไปก่อน
      reviewCount: _count(json['reviewCount']),
      salesCount: _count(json['salesCount']),
      officialSavedCount: _count(json['officialSavedCount']),
      communitySavedCount: _count(json['communitySavedCount']),
      commentsReceivedCount: _count(json['commentsReceivedCount']),
      reviewsWrittenCount: _count(json['reviewsWrittenCount']),
      avatarUrl: _resolveAvatarUrl(rawAvatarUrl, apiBaseUrl),
    );
  }

  static int _count(Object? value) => value is num ? value.toInt() : 0;

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
