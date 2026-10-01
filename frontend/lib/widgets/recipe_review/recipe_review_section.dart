import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/recipe_review/recipe_review_bloc.dart';
import 'package:flutter_application_1/bloc/recipe_review/recipe_review_event.dart';
import 'package:flutter_application_1/bloc/recipe_review/recipe_review_state.dart';
import 'package:flutter_application_1/models/recipe_review.dart';
import 'package:flutter_application_1/views/pages/recipe_reviews_page.dart';
import 'package:flutter_application_1/widgets/food_detail/food_detail_colors.dart';
import 'package:flutter_application_1/widgets/recipe_review/recipe_rate_dialog.dart';
import 'package:flutter_application_1/widgets/recipe_review/recipe_review_tile.dart';
import 'package:flutter_application_1/widgets/recipe_review/star_rating.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// ส่วน "คะแนนและรีวิว" ของหน้าสูตรอาหาร:
/// การ์ดคะแนนเฉลี่ย + กราฟแท่งแต่ละดาว + ปุ่มให้คะแนน แล้วตามด้วยรีวิวล่าสุด
/// ปุ่มให้คะแนนแสดงเฉพาะคนที่ซื้อสูตรแล้ว
class RecipeReviewSection extends StatelessWidget {
  const RecipeReviewSection({super.key});

  Future<void> _openRateDialog(BuildContext context, RecipeReview? mine) async {
    final stars = await RecipeRateDialog.show(context, initial: mine);
    if (stars == null || !context.mounted) return;
    await ReviewThanksDialog.show(context, stars: stars);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecipeReviewBloc, RecipeReviewState>(
      builder: (context, state) {
        if (state.status == RecipeReviewStatus.loading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.status == RecipeReviewStatus.failure) {
          return _LoadError(
            message: state.error ?? 'โหลดคะแนนไม่สำเร็จ',
            onRetry: () => context.read<RecipeReviewBloc>().add(
              const RecipeReviewRequested(),
            ),
          );
        }

        final summary = state.summary;
        final recipeId = context.read<RecipeReviewBloc>().recipeId;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RecipeReviewSummaryCard(
              summary: summary,
              // ยังไม่ซื้อ/ยังไม่ล็อกอิน = ไม่มีปุ่ม
              trailing: state.canReview
                  ? _RateButton(
                      label: state.myReview == null ? 'ให้คะแนน' : 'แก้ไขคะแนน',
                      onPressed: () => _openRateDialog(context, state.myReview),
                    )
                  : null,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'รีวิวล่าสุด',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (summary.count > 0)
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => RecipeReviewsPage(
                          recipeId: recipeId,
                          summary: summary,
                        ),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: FoodDetailColors.purple,
                    ),
                    child: const Text(
                      'ดูทั้งหมด',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (summary.reviews.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'ยังไม่มีรีวิว',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              )
            else
              for (final review in summary.reviews) ...[
                RecipeReviewTile(review: review),
                const SizedBox(height: 10),
              ],
          ],
        );
      },
    );
  }
}

/// การ์ด "คะแนนและรีวิว": หัวข้อ + ปุ่ม, คะแนนเฉลี่ยตัวใหญ่, กราฟแท่ง 5→1 ดาว
class RecipeReviewSummaryCard extends StatelessWidget {
  const RecipeReviewSummaryCard({
    super.key,
    required this.summary,
    this.title = 'คะแนนและรีวิว',
    this.trailing,
  });

  final RecipeReviewSummary summary;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.count == 0
                        ? '-'
                        : summary.average.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  StarRatingDisplay(rating: summary.average, size: 18),
                  const SizedBox(height: 4),
                  Text(
                    summary.count == 0
                        ? 'ยังไม่มีคะแนน'
                        : 'จาก ${summary.count} รีวิว',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    for (var stars = 5; stars >= 1; stars--)
                      _DistributionBar(
                        stars: stars,
                        fraction: summary.count == 0
                            ? 0
                            : summary.countFor(stars) / summary.count,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RateButton extends StatelessWidget {
  const _RateButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.star_outline_rounded, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: FoodDetailColors.purple,
        backgroundColor: FoodDetailColors.softPurple,
        side: const BorderSide(color: FoodDetailColors.purple),
        shape: const StadiumBorder(),
        visualDensity: VisualDensity.compact,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// แถว "5 ▬▬▬▬▬▬" สัดส่วนรีวิวของดาวนั้น
class _DistributionBar extends StatelessWidget {
  const _DistributionBar({required this.stars, required this.fraction});

  final int stars;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            child: Text(
              '$stars',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation(FoodDetailColors.star),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('ลองใหม่'),
            ),
          ],
        ),
      ),
    );
  }
}
