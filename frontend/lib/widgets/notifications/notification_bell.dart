import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/notification_center.dart';
import 'package:flutter_application_1/l10n/l10n.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_application_1/views/pages/login_page.dart';
import 'package:flutter_application_1/views/pages/notifications_page.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';

/// ปุ่มกระดิ่งวงกลมขาว มีจุดแดงบอกจำนวนที่ยังไม่อ่าน
/// ยังไม่ login = กดแล้วไปหน้า login ก่อน แล้วค่อยเปิดกล่องแจ้งเตือน
class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({super.key});

  static const badgeColor = Color(0xFFE5484D);

  Future<void> _open(BuildContext context) async {
    final navigator = Navigator.of(context);
    if (TokenStorage.currentUserId.value == null) {
      final signedIn = await LoginPage.signInAndReturn(context);
      if (!signedIn) return;
    }
    await navigator.push(
      MaterialPageRoute<void>(builder: (_) => const NotificationsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NotificationCenter.unreadCount,
      builder: (context, count, _) {
        final label = count > 9 ? '9+' : '$count';
        return Semantics(
          button: true,
          label: count > 0
              ? '${context.l10n.notificationsTooltip} ($count)'
              : context.l10n.notificationsTooltip,
          child: Tooltip(
            message: context.l10n.notificationsTooltip,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _open(context),
                child: SizedBox.square(
                  dimension: 40,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        count > 0
                            ? Icons.notifications_rounded
                            : Icons.notifications_none_rounded,
                        color: ProfileColors.ink,
                      ),
                      if (count > 0)
                        Positioned(
                          top: 4,
                          right: 2,
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 18),
                            height: 18,
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
