import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/banner_rating.dart';
import 'package:flutter_application_1/widgets/banner_detail/banner_detail_colors.dart';
import 'package:flutter_application_1/widgets/banner_detail/star_rating.dart';

/// ความคิดเห็นหนึ่งรายการ: รูปโปรไฟล์ ชื่อ ดาว และข้อความ
class BannerReviewTile extends StatelessWidget {
  const BannerReviewTile({super.key, required this.review});

  final BannerRating review;

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
            backgroundColor: BannerDetailColors.softOrange,
            foregroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
            child: Text(
              initial,
              style: const TextStyle(
                color: BannerDetailColors.accentOrange,
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
