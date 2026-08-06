class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    required this.avatarAssetPath,
    required this.roleLabel,
    required this.recipeCount,
    required this.purchasedCount,
    required this.savedCount,
    required this.draftCount,
    required this.rating,
  });

  final String id;
  final String displayName;
  final String email;
  final String avatarAssetPath;
  final String roleLabel;
  final int recipeCount;
  final int purchasedCount;
  final int savedCount;
  final int draftCount;
  final double rating;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      email: json['email'] as String,
      avatarAssetPath: json['avatarAssetPath'] as String,
      roleLabel: json['roleLabel'] as String,
      recipeCount: json['recipeCount'] as int,
      purchasedCount: json['purchasedCount'] as int,
      savedCount: json['savedCount'] as int,
      draftCount: json['draftCount'] as int,
      rating: (json['rating'] as num).toDouble(),
    );
  }
}
