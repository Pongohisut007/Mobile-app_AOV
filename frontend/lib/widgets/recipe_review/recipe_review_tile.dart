import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/recipe_review.dart';
import 'package:flutter_application_1/models/review_tag.dart';
import 'package:flutter_application_1/widgets/food_detail/food_detail_colors.dart';
import 'package:flutter_application_1/widgets/recipe_review/star_rating.dart';

/// รีวิวหนึ่งรายการ: รูปโปรไฟล์ ชื่อ ดาว และข้อความ
class RecipeReviewTile extends StatelessWidget {
  const RecipeReviewTile({super.key, required this.review});

  final RecipeReview review;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = review.userAvatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.startsWith('http');
    final name = review.userName.trim();
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
                        review.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (review.createdAt != null)
                      Text(
                        _formatDate(review.createdAt!),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                StarRatingDisplay(rating: review.rating.toDouble(), size: 16),
                if (review.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final tag in review.tags)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: FoodDetailColors.softPurple,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            ReviewTag.labelOf(tag),
                            style: const TextStyle(
                              fontSize: 12,
                              color: FoodDetailColors.purple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                if (review.comment.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    review.comment,
                    style: TextStyle(color: Colors.grey.shade800, height: 1.5),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
