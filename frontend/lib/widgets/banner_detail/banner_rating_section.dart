import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/banner_rating/banner_rating_bloc.dart';
import 'package:flutter_application_1/bloc/banner_rating/banner_rating_event.dart';
import 'package:flutter_application_1/bloc/banner_rating/banner_rating_state.dart';
import 'package:flutter_application_1/routes/app_routes.dart';
import 'package:flutter_application_1/widgets/banner_detail/banner_detail_colors.dart';
import 'package:flutter_application_1/widgets/banner_detail/banner_review_tile.dart';
import 'package:flutter_application_1/widgets/banner_detail/star_rating.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// ส่วนให้คะแนน: คะแนนเฉลี่ย, ดาว 5 ดวงให้กด, ช่องความคิดเห็น และความคิดเห็นล่าสุด
class BannerRatingSection extends StatefulWidget {
  const BannerRatingSection({super.key});

  @override
  State<BannerRatingSection> createState() => _BannerRatingSectionState();
}

class _BannerRatingSectionState extends State<BannerRatingSection> {
  static const _starLabels = ['แย่มาก', 'พอใช้', 'ดี', 'ดีมาก', 'ยอดเยี่ยม!'];

  final TextEditingController _commentController = TextEditingController();
  int _selectedStars = 0;

  // เติมคะแนนเดิมของเราแค่ครั้งแรกที่โหลดเสร็จ ไม่ทับสิ่งที่กำลังพิมพ์
  bool _prefilled = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _prefillFrom(BannerRatingState state) {
    if (_prefilled || state.status != BannerRatingStatus.ready) return;
    _prefilled = true;

    final mine = state.myRating;
    if (mine == null) return;
    setState(() => _selectedStars = mine.rating);
    _commentController.text = mine.comment;
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<BannerRatingBloc>().add(
      BannerRatingSubmitted(
        rating: _selectedStars,
        comment: _commentController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BannerRatingBloc, BannerRatingState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.submitStatus != current.submitStatus,
      listener: (context, state) {
        _prefillFrom(state);

        final messenger = ScaffoldMessenger.of(context);
        if (state.submitStatus == BannerRatingSubmitStatus.success) {
          messenger.showSnackBar(
            const SnackBar(content: Text('ขอบคุณสำหรับคะแนน!')),
          );
        } else if (state.submitStatus == BannerRatingSubmitStatus.failure &&
            state.error != null) {
          messenger.showSnackBar(SnackBar(content: Text(state.error!)));
        }
      },
      builder: (context, state) {
        if (state.status == BannerRatingStatus.loading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.status == BannerRatingStatus.failure) {
          return _LoadError(
            message: state.error ?? 'โหลดคะแนนไม่สำเร็จ',
            onRetry: () => context.read<BannerRatingBloc>().add(
              const BannerRatingRequested(),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RatingOverview(
              average: state.summary.average,
              count: state.summary.count,
            ),
            const SizedBox(height: 20),
            _buildRateCard(state),
            const SizedBox(height: 28),
            const Text(
              'ความคิดเห็นล่าสุด',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (state.summary.ratings.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'ยังไม่มีความคิดเห็น มาเป็นคนแรกกัน!',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              )
            else
              for (final review in state.summary.ratings) ...[
                BannerReviewTile(review: review),
                const SizedBox(height: 10),
              ],
          ],
        );
      },
    );
  }

  Widget _buildRateCard(BannerRatingState state) {
    final hasRated = state.myRating != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BannerDetailColors.softOrange,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            hasRated ? 'คะแนนของคุณ' : 'ให้คะแนน event นี้',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            state.isLoggedIn
                ? 'แตะดาวเพื่อเลือกคะแนน'
                : 'เข้าสู่ระบบก่อนจึงจะให้คะแนนได้',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 14),
          StarRatingInput(
            value: _selectedStars,
            enabled: state.isLoggedIn && !state.isSubmitting,
            onChanged: (stars) => setState(() => _selectedStars = stars),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _selectedStars == 0 ? ' ' : _starLabels[_selectedStars - 1],
              key: ValueKey(_selectedStars),
              style: const TextStyle(
                color: BannerDetailColors.accentOrange,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (state.isLoggedIn) ...[
            TextField(
              controller: _commentController,
              enabled: !state.isSubmitting,
              maxLines: 3,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: 'เล่าความรู้สึกของคุณเกี่ยวกับ event นี้ (ไม่บังคับ)',
                filled: true,
                fillColor: Colors.white,
                counterText: '',
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _selectedStars == 0 || state.isSubmitting
                    ? null
                    : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: BannerDetailColors.primaryRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: state.isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        hasRated ? 'อัปเดตคะแนน' : 'ส่งคะแนน',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ] else
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                icon: const Icon(Icons.login_rounded),
                label: const Text('เข้าสู่ระบบเพื่อให้คะแนน'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: BannerDetailColors.primaryRed,
                  side: const BorderSide(color: BannerDetailColors.primaryRed),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// คะแนนเฉลี่ยตัวใหญ่ + ดาว + จำนวนรีวิว
class _RatingOverview extends StatelessWidget {
  const _RatingOverview({required this.average, required this.count});

  final double average;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          count == 0 ? '-' : average.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StarRatingDisplay(rating: average, size: 22),
            const SizedBox(height: 4),
            Text(
              count == 0 ? 'ยังไม่มีคะแนน' : 'จาก $count รีวิว',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
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
