import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/common/app_dialog.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';

/// หน้าตา bottom sheet ทั้งแอป ใส่ไว้ใน ThemeData แล้ว
/// พื้นขาว มุมบนโค้ง 28 มีขีดจับลากสีเทาอ่อน
const appBottomSheetTheme = BottomSheetThemeData(
  backgroundColor: Colors.white,
  modalBackgroundColor: Colors.white,
  surfaceTintColor: Colors.transparent,
  showDragHandle: true,
  dragHandleColor: Color(0xFFDADAD3),
  dragHandleSize: Size(40, 4),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
  clipBehavior: Clip.antiAlias,
);

Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: true,
    builder: builder,
  );
}

/// หัวชีต: หัวข้อตัวหนา + คำอธิบายสีเทา (ถ้ามี)
class AppSheetHeader extends StatelessWidget {
  const AppSheetHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: ProfileColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: const TextStyle(
                color: ProfileColors.muted,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// ตัวเลือกในชีต: การ์ดมน ไอคอนในกรอบ + ข้อความ  [selected] = ขอบเข้ม + เครื่องหมายถูก
class AppSheetOption extends StatelessWidget {
  const AppSheetOption({
    super.key,
    required this.title,
    required this.onTap,
    this.icon,
    this.subtitle,
    this.selected = false,
    this.selectable = false,
    this.danger = false,
  });

  final IconData? icon;
  final String title;
  final String? subtitle;
  final bool selected;

  /// ใช้เป็นตัวเลือกแบบเลือกได้ 1 อัน (เช่น ภาษา) ตัวที่ไม่ได้เลือกโชว์วงกลมเปล่าแทนลูกศร
  final bool selectable;
  final bool danger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppDialogColors.danger : ProfileColors.ink;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? AppDialogColors.neutralSoft : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected ? ProfileColors.ink : const Color(0xFFE7E7E1),
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: danger
                          ? AppDialogColors.dangerSoft
                          : AppDialogColors.neutralSoft,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, size: 22, color: color),
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: color,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            color: ProfileColors.muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: ProfileColors.ink,
                    size: 22,
                  )
                else if (selectable)
                  const Icon(
                    Icons.radio_button_unchecked_rounded,
                    color: Color(0xFFCFCFC8),
                    size: 22,
                  )
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFB9BAB2),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
