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
  final double rating;

  factory UserProfile.guest() {
    return const UserProfile(
      id: '',
      displayName: 'Guest',
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

  String get roleLabel => switch (role) {
    'creator' => 'Recipe creator',
    'admin' => 'Administrator',
    _ => 'Food lover',
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
      avatarUrl: _resolveAvatarUrl(rawAvatarUrl, apiBaseUrl),
    );
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
