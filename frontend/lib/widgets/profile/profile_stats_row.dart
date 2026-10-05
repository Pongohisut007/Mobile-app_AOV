import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/common/app_shadows.dart';
import 'package:flutter_application_1/models/user_profile.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';
import 'package:flutter_application_1/l10n/l10n.dart';

/// ตัวเลขผลงานบนหน้าโปรไฟล์ แยกตามบทบาท (ไม่ซ้ำกับการ์ดลัดข้างล่าง)
/// - creator: คะแนนสูตร / ขายได้ / บันทึกสูตร official / บันทึกสูตรคอมมูนิตี้ (2x2)
/// - user: ถูกบันทึก / ความคิดเห็นที่ได้รับ / รีวิวที่เขียน (แถวเดียว)
/// ผู้เยี่ยมชมไม่ต้องแสดง (หน้าโปรไฟล์ซ่อนเอง)
class ProfileStatsRow extends StatelessWidget {
  const ProfileStatsRow({super.key, required this.profile});

  final UserProfile profile;

  static const _gap = 10.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (!profile.isCreator) {
      return _row([
        _StatCard(
          value: '${profile.communitySavedCount}',
          label: l10n.statSavesReceived,
          icon: Icons.favorite_rounded,
          iconColor: Colors.redAccent,
        ),
        _StatCard(
          value: '${profile.commentsReceivedCount}',
          label: l10n.statCommentsReceived,
          icon: Icons.chat_bubble_rounded,
          iconColor: const Color(0xFF6650A5),
        ),
        _StatCard(
          value: '${profile.reviewsWrittenCount}',
          label: l10n.statReviewsWritten,
          icon: Icons.rate_review_rounded,
          iconColor: const Color(0xFF24BDB8),
        ),
      ]);
    }

    final hasReviews = profile.reviewCount > 0;
    return Column(
      children: [
        _row([
          _StatCard(
            // ยังไม่มีรีวิวแสดง "–" ไม่ใช่ 0.0 ที่ดูเหมือนได้คะแนนแย่
            value: hasReviews ? profile.rating.toStringAsFixed(1) : '–',
            label: l10n.statRecipeRating,
            caption: hasReviews
                ? l10n.reviewsCountShort(profile.reviewCount)
                : l10n.noReviewsYet,
            icon: Icons.star_rounded,
            iconColor: Colors.amber,
          ),
          _StatCard(
            value: '${profile.salesCount}',
            label: l10n.statSales,
            icon: Icons.shopping_bag_rounded,
            iconColor: const Color(0xFF2E7D32),
          ),
        ]),
        const SizedBox(height: _gap),
        _row([
          _StatCard(
            value: '${profile.officialSavedCount}',
            label: l10n.statOfficialSaves,
            icon: Icons.favorite_rounded,
            iconColor: Colors.redAccent,
          ),
          _StatCard(
            value: '${profile.communitySavedCount}',
            label: l10n.statCommunitySaves,
            icon: Icons.favorite_border_rounded,
            iconColor: Colors.redAccent,
          ),
        ]),
      ],
    );
  }

  // การ์ดในแถวเดียวกันสูงเท่ากัน (การ์ดคะแนนมีบรรทัดจำนวนรีวิวเพิ่ม)
  static Widget _row(List<Widget> cards) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, card) in cards.indexed) ...[
            if (index > 0) const SizedBox(width: _gap),
            Expanded(child: card),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    this.caption,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;

  /// บรรทัดเล็กใต้ป้าย เช่น "12 รีวิว"
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final caption = this.caption;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ProfileColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ProfileColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(
              caption,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}
