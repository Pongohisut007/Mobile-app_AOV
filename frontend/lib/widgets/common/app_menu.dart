import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/common/app_dialog.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';

/// หน้าตาเมนู 3 จุด (PopupMenuButton) ทั้งแอป ใส่ไว้ใน ThemeData แล้ว
/// การ์ดขาวมุมโค้ง เงาฟุ้ง โผล่ใต้ปุ่มแทนการทับปุ่ม
const appPopupMenuTheme = PopupMenuThemeData(
  color: Colors.white,
  surfaceTintColor: Colors.transparent,
  elevation: 10,
  shadowColor: Color(0x33000000),
  position: PopupMenuPosition.under,
  menuPadding: EdgeInsets.symmetric(vertical: 6),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(18)),
  ),
);

/// รายการในเมนู: ไอคอนในกรอบมน + ข้อความ  [danger] = สีแดง (ลบ ฯลฯ)
PopupMenuItem<T> appMenuItem<T>({
  required T value,
  required IconData icon,
  required String label,
  bool danger = false,
}) {
  final color = danger ? AppDialogColors.danger : ProfileColors.ink;
  return PopupMenuItem<T>(
    value: value,
    height: 52,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 168),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: danger
                  ? AppDialogColors.dangerSoft
                  : AppDialogColors.neutralSoft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
