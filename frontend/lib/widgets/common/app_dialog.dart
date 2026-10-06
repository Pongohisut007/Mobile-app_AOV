import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';

/// หน้าตา dialog กลางของแอป (โทนเดียวกับหน้าโปรไฟล์/ตะกร้า/ตั้งค่า)
/// การ์ดขาวมุมโค้ง + ไอคอนในวงกลม + หัวข้อกลาง + ปุ่มทรงแคปซูลเต็มความกว้างเรียงลงมา
/// ปุ่มเรียงแนวตั้งเพราะข้อความไทยยาว ("ออกโดยไม่บันทึก") วางเรียงข้างกันแล้วล้น
abstract final class AppDialogColors {
  static const danger = Color(0xFFD54444);
  static const dangerSoft = Color(0xFFFDECEC);
  static const neutralSoft = Color(0xFFF1F1EC);
}

enum AppDialogActionStyle {
  /// ปุ่มทึบ (การกระทำหลัก)
  primary,

  /// ปุ่มขอบ (ทางเลือกรอง)
  secondary,

  /// ตัวหนังสือเฉย ๆ (ยกเลิก/อยู่ต่อ)
  text,
}

class AppDialogAction<T> {
  const AppDialogAction({
    required this.label,
    required this.value,
    this.style = AppDialogActionStyle.primary,
    this.danger = false,
  });

  final String label;

  /// ค่าที่ dialog คืนเมื่อกดปุ่มนี้
  final T value;
  final AppDialogActionStyle style;

  /// สีแดง (ลบ/ออกโดยไม่บันทึก ฯลฯ)
  final bool danger;
}

/// เปิด dialog ตามแบบของแอป คืนค่าของปุ่มที่กด (ปิดด้วยการแตะข้างนอก/ปุ่มย้อนกลับ = null)
Future<T?> showAppDialog<T>(
  BuildContext context, {
  required IconData icon,
  required String title,
  String? message,
  Widget? content,
  required List<AppDialogAction<T>> actions,
  bool danger = false,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) => AppDialog(
      icon: icon,
      title: title,
      message: message,
      content: content,
      danger: danger,
      actions: [
        for (final action in actions)
          AppDialogButton(
            label: action.label,
            style: action.style,
            danger: action.danger,
            onPressed: () => Navigator.of(dialogContext).pop(action.value),
          ),
      ],
    ),
  );
}

/// ยืนยัน/ยกเลิก คืน true เมื่อกดยืนยันเท่านั้น
Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  bool danger = false,
}) async {
  final confirmed = await showAppDialog<bool>(
    context,
    icon: icon,
    title: title,
    message: message,
    danger: danger,
    actions: [
      AppDialogAction(label: confirmLabel, value: true, danger: danger),
      AppDialogAction(
        label: cancelLabel,
        value: false,
        style: AppDialogActionStyle.text,
      ),
    ],
  );
  return confirmed ?? false;
}

/// ตัว dialog (ใช้ตรง ๆ ได้เมื่อมีเนื้อหาพิเศษ เช่น ช่องพิมพ์ที่ต้องจัดการ state เอง)
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    required this.actions,
    this.icon,
    this.leading,
    this.message,
    this.content,
    this.danger = false,
  });

  final IconData? icon;

  /// ใช้แทน [icon] เมื่ออยากใส่รูป เช่น โลโก้แอป
  final Widget? leading;
  final String title;
  final String? message;
  final Widget? content;
  final List<Widget> actions;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (leading != null)
                Center(child: leading)
              else if (icon != null)
                Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: danger
                          ? AppDialogColors.dangerSoft
                          : AppDialogColors.neutralSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 30,
                      color: danger
                          ? AppDialogColors.danger
                          : ProfileColors.ink,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ProfileColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ProfileColors.muted,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
              if (content != null) ...[const SizedBox(height: 16), content!],
              const SizedBox(height: 22),
              for (final (index, action) in actions.indexed) ...[
                if (index > 0) const SizedBox(height: 8),
                action,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// ปุ่มใน [AppDialog]
class AppDialogButton extends StatelessWidget {
  const AppDialogButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = AppDialogActionStyle.primary,
    this.danger = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppDialogActionStyle style;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppDialogColors.danger : ProfileColors.ink;
    const textStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w800);
    const size = Size.fromHeight(52);
    final child = Text(label, textAlign: TextAlign.center);

    return switch (style) {
      AppDialogActionStyle.primary => FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withValues(alpha: 0.4),
          minimumSize: size,
          shape: const StadiumBorder(),
          textStyle: textStyle,
        ),
        child: child,
      ),
      AppDialogActionStyle.secondary => OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.35), width: 1.5),
          minimumSize: size,
          shape: const StadiumBorder(),
          textStyle: textStyle,
        ),
        child: child,
      ),
      AppDialogActionStyle.text => TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: danger
              ? AppDialogColors.danger
              : ProfileColors.muted,
          minimumSize: const Size.fromHeight(46),
          shape: const StadiumBorder(),
          textStyle: textStyle.copyWith(fontWeight: FontWeight.w700),
        ),
        child: child,
      ),
    };
  }
}
