import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';

/// ประเภทข้อความ เปลี่ยนไอคอน/สีให้รู้ทันทีว่าสำเร็จหรือผิดพลาด
enum AppSnackType { info, success, error }

/// SnackBar แบบลอย มุมโค้ง พื้นเข้ม มีไอคอนตามประเภท ใช้ทั้งแอป
SnackBar appSnackBar(String message, {AppSnackType type = AppSnackType.info}) {
  final (icon, iconColor, badgeColor) = switch (type) {
    AppSnackType.success => (
      Icons.check_rounded,
      ProfileColors.ink,
      ProfileColors.accent,
    ),
    AppSnackType.error => (
      Icons.error_outline_rounded,
      Colors.white,
      const Color(0xFFE5484D),
    ),
    AppSnackType.info => (
      Icons.info_outline_rounded,
      Colors.white,
      Colors.white.withValues(alpha: 0.14),
    ),
  };

  return SnackBar(
    // error อยู่นานกว่าหน่อย ให้อ่านข้อความทัน
    duration: Duration(seconds: type == AppSnackType.error ? 5 : 3),
    dismissDirection: DismissDirection.horizontal,
    content: Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(message, maxLines: 4, overflow: TextOverflow.ellipsis),
        ),
      ],
    ),
  );
}

/// หน้าตากลางของ SnackBar ทั้งแอป (ใส่ใน ThemeData)
/// ที่ไหนสร้าง SnackBar เองโดยไม่ผ่าน [appSnackBar] ก็ยังได้หน้าตาเดียวกัน
const appSnackBarTheme = SnackBarThemeData(
  behavior: SnackBarBehavior.floating,
  backgroundColor: ProfileColors.ink,
  elevation: 8,
  insetPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(18)),
  ),
  contentTextStyle: TextStyle(
    color: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.35,
  ),
  actionTextColor: ProfileColors.accent,
);

extension AppSnackBarMessenger on ScaffoldMessengerState {
  /// ซ่อนอันเดิม (ถ้ามี) แล้วแสดงข้อความใหม่ ข้อความจะได้ไม่ต่อคิวกันยาว
  void showAppSnackBar(
    String message, {
    AppSnackType type = AppSnackType.info,
  }) {
    this
      ..hideCurrentSnackBar()
      ..showSnackBar(appSnackBar(message, type: type));
  }
}

/// ทางลัดจาก BuildContext
void showAppSnackBar(
  BuildContext context,
  String message, {
  AppSnackType type = AppSnackType.info,
}) {
  ScaffoldMessenger.of(context).showAppSnackBar(message, type: type);
}
