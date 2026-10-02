import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/models/recipe_comment.dart';
import 'package:flutter_application_1/widgets/food_detail/food_detail_colors.dart';

class RecipeCommentTile extends StatelessWidget {
  const RecipeCommentTile({super.key, required this.comment});

  final RecipeComment comment;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = _resolveAvatarUrl(
      comment.userAvatarUrl,
      ApiConfig.apiBaseUrl,
    );
    final hasAvatar = avatarUrl != null;
    final name = comment.userName.trim();
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: FoodDetailColors.softOrange,
            foregroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
            child: Text(
              initial,
              style: const TextStyle(
                color: FoodDetailColors.accentOrange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (comment.createdAt != null)
                      Text(
                        _formatDate(comment.createdAt!),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  comment.comment,
                  style: TextStyle(color: Colors.grey.shade800, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

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