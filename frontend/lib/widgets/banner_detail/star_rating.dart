import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/banner_detail/banner_detail_colors.dart';

/// ดาว 5 ดวงแบบดูอย่างเดียว รองรับครึ่งดวง เช่น 3.5
class StarRatingDisplay extends StatelessWidget {
  const StarRatingDisplay({super.key, required this.rating, this.size = 18});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final position = index + 1;
        final IconData icon;
        if (rating >= position) {
          icon = Icons.star_rounded;
        } else if (rating >= position - 0.5) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_outline_rounded;
        }
        return Icon(
          icon,
          size: size,
          color: icon == Icons.star_outline_rounded
              ? BannerDetailColors.starEmpty
              : BannerDetailColors.star,
        );
      }),
    );
  }
}

/// ดาว 5 ดวงให้กดเลือกคะแนน 1-5 ดวงที่ถูกเลือกจะเด้งขึ้นเล็กน้อย
class StarRatingInput extends StatelessWidget {
  const StarRatingInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 44,
    this.enabled = true,
  });

  /// 0 = ยังไม่ได้เลือก
  final int value;
  final ValueChanged<int> onChanged;
  final double size;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final star = index + 1;
        final isSelected = star <= value;

        return Semantics(
          button: true,
          label: '$star ดาว',
          selected: star == value,
          child: InkResponse(
            onTap: enabled ? () => onChanged(star) : null,
            radius: size * 0.7,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AnimatedScale(
                scale: isSelected ? 1.12 : 1,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutBack,
                child: Icon(
                  isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: size,
                  color: isSelected
                      ? BannerDetailColors.star
                      : Colors.grey.shade400,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
