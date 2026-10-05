import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/models/recipe_comment.dart';
import 'package:flutter_application_1/widgets/common/app_network_image.dart';
import 'package:flutter_application_1/widgets/food_detail/food_detail_colors.dart';
import 'package:flutter_application_1/widgets/recipe_comment/comment_text.dart';
import 'package:flutter_application_1/l10n/l10n.dart';

class RecipeCommentTile extends StatelessWidget {
  const RecipeCommentTile({
    super.key,
    required this.comment,
    this.isOwner = false,
    this.onEdit,
    this.onDelete,
    this.isBusy = false,
  });

  final RecipeComment comment;
  final bool isOwner;

  /// กำลังแก้ไข/ลบคอมเมนต์นี้อยู่: แสดงตัวหมุนแทนเมนู
  final bool isBusy;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

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
            foregroundImage: hasAvatar
                ? appNetworkImageProvider(context, avatarUrl, logicalSize: 40)
                : null,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment.userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (comment.createdAt != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                _formatDate(comment.createdAt!),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isOwner && isBusy)
                      const SizedBox.square(
                        dimension: 32,
                        child: Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    else if (isOwner)
                      SizedBox.square(
                        dimension: 32,
                        child: PopupMenuButton<String>(
                          enabled: onEdit != null || onDelete != null,
                          tooltip: context.l10n.manageComment,
                          padding: EdgeInsets.zero,
                          iconSize: 18,
                          icon: const Icon(Icons.more_horiz),
                          onSelected: (action) {
                            if (action == 'edit') onEdit?.call();
                            if (action == 'delete') onDelete?.call();
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 18),
                                  SizedBox(width: 8),
                                  Text(context.l10n.edit),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 18),
                                  SizedBox(width: 8),
                                  Text(context.l10n.delete),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                CommentText(comment: comment.comment),
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
