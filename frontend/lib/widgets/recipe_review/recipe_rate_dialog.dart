import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/recipe_review/recipe_review_bloc.dart';
import 'package:flutter_application_1/bloc/recipe_review/recipe_review_event.dart';
import 'package:flutter_application_1/bloc/recipe_review/recipe_review_state.dart';
import 'package:flutter_application_1/models/recipe_review.dart';
import 'package:flutter_application_1/models/review_tag.dart';
import 'package:flutter_application_1/widgets/food_detail/food_detail_colors.dart';
import 'package:flutter_application_1/widgets/recipe_review/star_rating.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// ป๊อปอัปให้คะแนน: ดาว 5 ดวง, ชิป "ชอบอะไรในสูตรนี้", ช่องเล่าเพิ่มเติม
/// ส่งสำเร็จแล้วจะปิดตัวเองพร้อมคืนคะแนนที่ให้ (ยกเลิก = null)
class RecipeRateDialog extends StatefulWidget {
  const RecipeRateDialog({super.key, this.initial});

  /// รีวิวเดิมของเรา ถ้ามีจะเติมไว้ให้แก้ต่อ
  final RecipeReview? initial;

  /// เปิดป๊อปอัปโดยส่ง bloc ของหน้าสูตรต่อเข้าไปด้วย
  static Future<int?> show(BuildContext context, {RecipeReview? initial}) {
    final bloc = context.read<RecipeReviewBloc>();
    return showDialog<int>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: RecipeRateDialog(initial: initial),
      ),
    );
  }

  @override
  State<RecipeRateDialog> createState() => _RecipeRateDialogState();
}

class _RecipeRateDialogState extends State<RecipeRateDialog> {
  static const _starLabels = ['แย่มาก', 'พอใช้', 'ดี', 'ดีมาก', 'ยอดเยี่ยม!'];
  static const _maxCommentLength = 500;

  late int _stars = widget.initial?.rating ?? 0;
  late final Set<String> _tags = {...?widget.initial?.tags};
  late final TextEditingController _commentController = TextEditingController(
    text: widget.initial?.comment ?? '',
  );

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<RecipeReviewBloc>().add(
      RecipeReviewSubmitted(
        rating: _stars,
        comment: _commentController.text,
        // เรียงตามลำดับชิปบนจอ ไม่ใช่ลำดับที่กด
        tags: ReviewTag.options.keys.where(_tags.contains).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RecipeReviewBloc, RecipeReviewState>(
      listenWhen: (previous, current) =>
          previous.submitStatus != current.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == RecipeReviewSubmitStatus.success) {
          Navigator.of(context).pop(_stars);
        } else if (state.submitStatus == RecipeReviewSubmitStatus.failure &&
            state.error != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.error!)));
        }
      },
      builder: (context, state) {
        final busy = state.isSubmitting;

        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: _CloseButton(
                      onPressed: busy ? null : () => Navigator.pop(context),
                    ),
                  ),
                  const Center(
                    child: Text(
                      'ให้คะแนนสูตรนี้',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'ความคิดเห็นของคุณช่วยให้เราพัฒนาสูตรอาหารให้ดียิ่งขึ้น',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  StarRatingInput(
                    value: _stars,
                    size: 40,
                    enabled: !busy,
                    onChanged: (stars) => setState(() => _stars = stars),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _stars == 0
                            ? 'แตะดาวเพื่อให้คะแนน'
                            : _starLabels[_stars - 1],
                        key: ValueKey(_stars),
                        style: TextStyle(
                          color: _stars == 0
                              ? Colors.grey.shade500
                              : FoodDetailColors.accentOrange,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'ชอบอะไรในสูตรนี้',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final MapEntry(key: key, value: label)
                          in ReviewTag.options.entries)
                        _TagChip(
                          label: label,
                          selected: _tags.contains(key),
                          onTap: busy
                              ? null
                              : () => setState(() {
                                  if (!_tags.remove(key)) _tags.add(key);
                                }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text.rich(
                    TextSpan(
                      text: 'เล่าเพิ่มเติม ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                          text: '(ไม่บังคับ)',
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _commentController,
                    enabled: !busy,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: _maxCommentLength,
                    decoration: InputDecoration(
                      hintText: 'เล่าว่าทำสูตรนี้แล้วเป็นยังไงบ้าง',
                      filled: true,
                      fillColor: const Color(0xFFF8F7FC),
                      contentPadding: const EdgeInsets.all(14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: FoodDetailColors.purple,
                        ),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _stars == 0 || busy ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: FoodDetailColors.purple,
                        shape: const StadiumBorder(),
                      ),
                      child: busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              widget.initial == null
                                  ? 'ส่งคะแนน'
                                  : 'อัปเดตคะแนน',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// ป๊อปอัป "ขอบคุณสำหรับคะแนน!" หลังส่งสำเร็จ
class ReviewThanksDialog extends StatelessWidget {
  const ReviewThanksDialog({super.key, required this.stars});

  final int stars;

  static Future<void> show(BuildContext context, {required int stars}) {
    return showDialog<void>(
      context: context,
      builder: (_) => ReviewThanksDialog(stars: stars),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: _CloseButton(onPressed: () => Navigator.pop(context)),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: FoodDetailColors.softPurple,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 34,
                  color: FoodDetailColors.purple,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'ขอบคุณสำหรับคะแนน!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              StarRatingDisplay(rating: stars.toDouble(), size: 26),
              const SizedBox(height: 10),
              Text(
                'รีวิวของคุณถูกเพิ่มในหน้าสูตรแล้ว\n'
                'แก้ไขได้ทุกเมื่อจากปุ่ม "แก้ไขคะแนน"',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: FoodDetailColors.purple,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    'กลับไปที่สูตร',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: 'ปิด',
      style: IconButton.styleFrom(
        backgroundColor: Colors.grey.shade100,
        minimumSize: const Size(36, 36),
        fixedSize: const Size(36, 36),
        padding: EdgeInsets.zero,
      ),
      icon: Icon(Icons.close_rounded, size: 20, color: Colors.grey.shade700),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? FoodDetailColors.softPurple : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? FoodDetailColors.purple : Colors.grey.shade300,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? FoodDetailColors.purple : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}
