import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/common/app_shadows.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';

/// สีและหน้าตาที่ใช้ร่วมกันในหน้าสร้าง/แก้ไขสูตร และหน้าขั้นตอนข้างใน
/// อิงธีมเดียวกับหน้า Profile (ink/muted/background) + สีส้มของหน้า Home
class RecipeFormStyle {
  const RecipeFormStyle._();

  static const background = ProfileColors.background;
  static const ink = ProfileColors.ink;
  static const muted = ProfileColors.muted;

  /// ปุ่มหลัก (เผยแพร่/บันทึก) และขอบช่องตอนกำลังพิมพ์
  static const primary = Color(0xFFCE4D35);
  static const accent = Color(0xFFE64A19);
  static const accentSoft = Color(0xFFFFF3E0);

  /// พื้นช่องกรอกที่อยู่ในการ์ดสีขาว
  static const fieldFill = Color(0xFFF6F5F0);
  static const border = Color(0xFFE8E6DF);

  static const cardRadius = 20.0;
  static const fieldRadius = 14.0;

  static InputDecoration input({
    String? label,
    String? hint,
    Widget? prefixIcon,
    String? prefixText,
    String? suffixText,
    bool alignLabelWithHint = false,
    bool isDense = false,
  }) {
    OutlineInputBorder outline(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      prefixText: prefixText,
      suffixText: suffixText,
      alignLabelWithHint: alignLabelWithHint,
      isDense: isDense,
      filled: true,
      fillColor: fieldFill,
      labelStyle: const TextStyle(color: muted, fontWeight: FontWeight.w500),
      floatingLabelStyle: const TextStyle(
        color: primary,
        fontWeight: FontWeight.w700,
      ),
      hintStyle: TextStyle(color: Colors.grey.shade500),
      suffixStyle: const TextStyle(color: muted, fontWeight: FontWeight.w600),
      prefixStyle: const TextStyle(color: ink, fontWeight: FontWeight.w700),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isDense ? 12 : 16,
      ),
      border: outline(Colors.transparent),
      enabledBorder: outline(Colors.transparent),
      focusedBorder: outline(primary, 1.5),
      errorBorder: outline(Colors.red.shade300),
      focusedErrorBorder: outline(Colors.red.shade400, 1.5),
    );
  }

  static ButtonStyle primaryButton({double height = 54}) =>
      FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: primary.withValues(alpha: 0.45),
        disabledForegroundColor: Colors.white,
        minimumSize: Size.fromHeight(height),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      );

  static ButtonStyle secondaryButton({double height = 54}) =>
      OutlinedButton.styleFrom(
        foregroundColor: primary,
        backgroundColor: Colors.white,
        side: const BorderSide(color: primary, width: 1.5),
        minimumSize: Size.fromHeight(height),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      );

  static AppBar appBar({
    required String title,
    Widget? leading,
    List<Widget>? actions,
  }) => AppBar(
    backgroundColor: background,
    foregroundColor: ink,
    surfaceTintColor: Colors.transparent,
    scrolledUnderElevation: 0,
    leading: leading,
    actions: actions,
    title: Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: ink,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
    ),
  );
}

/// การ์ดสีขาวมุมโค้งที่ครอบแต่ละส่วนของฟอร์ม
class RecipeFormCard extends StatelessWidget {
  const RecipeFormCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin = const EdgeInsets.only(bottom: 14),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(RecipeFormStyle.cardRadius);
    // พื้นการ์ดเป็น Material: ListTile/CheckboxListTile ข้างในวาด ink splash บนการ์ดได้
    // (ถ้าเป็นกล่องสีธรรมดา Flutter เตือนว่า ink splash จะถูกบังมองไม่เห็น)
    return Padding(
      padding: margin,
      child: ShadowBox(
        borderRadius: radius,
        child: Material(
          color: Colors.white,
          borderRadius: radius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// ชิปเลือกได้ทีละอัน (ระดับความยาก, ประเภทสูตร ฯลฯ)
class RecipeChoiceChip extends StatelessWidget {
  const RecipeChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelected,
        customBorder: const StadiumBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: ShapeDecoration(
            color: selected ? RecipeFormStyle.ink : RecipeFormStyle.fieldFill,
            shape: const StadiumBorder(),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 17,
                  color: selected
                      ? ProfileColors.accent
                      : RecipeFormStyle.accent,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : RecipeFormStyle.ink,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ปุ่มเส้นประเต็มความกว้าง ใช้ "เพิ่ม..." ในหน้าขั้นตอน
class RecipeAddButton extends StatelessWidget {
  const RecipeAddButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.add_rounded,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final color = enabled ? RecipeFormStyle.primary : RecipeFormStyle.muted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(RecipeFormStyle.cardRadius),
        child: CustomPaint(
          painter: _DashedBorderPainter(color: color.withValues(alpha: 0.6)),
          child: Container(
            height: 56,
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(RecipeFormStyle.cardRadius),
    );
    final path = Path()..addRRect(rrect.deflate(0.75));
    const dash = 7.0;
    const gap = 5.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
