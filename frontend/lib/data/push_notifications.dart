import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/config/firebase_config.dart';
import 'package:flutter_application_1/data/notification_center.dart';
import 'package:flutter_application_1/l10n/l10n.dart';
import 'package:flutter_application_1/repositories/notification_repository.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_application_1/models/app_notification.dart';
import 'package:flutter_application_1/widgets/common/app_snack_bar.dart';
import 'package:flutter_application_1/widgets/common/session_expiry_listener.dart';
import 'package:flutter_application_1/widgets/notifications/notification_route.dart';

enum PushPermission {
  granted,
  denied,

  /// ไม่ได้ตั้งค่า Firebase ใน config / แพลตฟอร์มนี้ไม่รองรับ
  unavailable,
}

/// push notification ผ่าน Firebase Cloud Messaging (ใช้แค่ส่วน Messaging)
/// - แอปปิดอยู่/อยู่เบื้องหลัง: ระบบแสดงแจ้งเตือนเอง กดแล้วเปิดหน้าสูตร
/// - แอปเปิดอยู่: ไม่เด้งแจ้งเตือนของระบบ แสดงเป็น snackbar และอัปเดตตัวเลขบนกระดิ่งแทน
/// ไม่ได้ตั้งค่า Firebase = ทุกฟังก์ชันไม่ทำอะไร แอปส่วนอื่นใช้ได้ปกติ
abstract final class PushNotifications {
  static NotificationRepository repository = HttpNotificationRepository(
    baseUrl: ApiConfig.apiBaseUrl,
  );
  static TokenStorage storage = TokenStorage();

  static bool _ready = false;
  static RemoteMessage? _initialMessage;

  static bool get isAvailable => _ready;

  /// เรียกก่อน runApp (ไม่ขอสิทธิ์ตรงนี้ ขอเมื่อผู้ใช้เห็นประโยชน์แล้ว)
  static Future<void> init() async {
    final options = FirebaseConfig.currentPlatform;
    if (options == null) return;
    try {
      await Firebase.initializeApp(options: options);
      _ready = true;
    } catch (error) {
      debugPrint('Push notifications are off: $error');
      return;
    }

    final messaging = FirebaseMessaging.instance;
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_openFromPush);
    messaging.onTokenRefresh.listen((_) => unawaited(syncDevice()));
    // ภาษาของข้อความ push ตามภาษาที่เลือกในแอป
    AppLanguage.notifier.addListener(() => unawaited(syncDevice()));
    // เปิดแอปจากการกด push ตอนแอปปิดอยู่: รอหน้าแรกวาดเสร็จก่อนค่อยเปิดหน้าสูตร
    _initialMessage = await messaging.getInitialMessage();
  }

  /// เรียกหลัง runApp
  static void openInitialMessage() {
    final message = _initialMessage;
    if (message == null) return;
    _initialMessage = null;
    WidgetsBinding.instance.addPostFrameCallback((_) => _openFromPush(message));
  }

  /// ขอสิทธิ์แสดงแจ้งเตือน (Android 13+/iOS จะถามผู้ใช้ครั้งแรกเท่านั้น)
  /// ได้สิทธิ์แล้วลงทะเบียนเครื่องนี้กับ backend ทันที
  static Future<PushPermission> requestPermission() async {
    if (!_ready) return PushPermission.unavailable;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (!_isAllowed(settings.authorizationStatus)) {
        return PushPermission.denied;
      }
      await syncDevice();
      return PushPermission.granted;
    } catch (_) {
      return PushPermission.unavailable;
    }
  }

  static Future<PushPermission> currentPermission() async {
    if (!_ready) return PushPermission.unavailable;
    try {
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      return _isAllowed(settings.authorizationStatus)
          ? PushPermission.granted
          : PushPermission.denied;
    } catch (_) {
      return PushPermission.unavailable;
    }
  }

  /// บอก backend ว่าเครื่องนี้ (ของบัญชีที่ login อยู่) รับ push ได้
  /// ยังไม่ได้สิทธิ์ = ไม่ถามผู้ใช้ตรงนี้ (กันเด้งถามตอนเปิดแอป)
  static Future<void> syncDevice() async {
    if (!_ready) return;
    final accessToken = (await storage.readAccessToken())?.trim();
    if (accessToken == null || accessToken.isEmpty) return;
    try {
      if (await currentPermission() != PushPermission.granted) return;
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await repository.registerDevice(
        accessToken,
        token: token,
        platform: defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android',
        locale: AppLanguage.current.languageCode,
      );
    } catch (error) {
      debugPrint('Could not register this device for push: $error');
    }
  }

  /// เลิกส่ง push มาเครื่องนี้ (ออกจากระบบ / session หมดอายุ)
  static Future<void> unregisterDevice() async {
    if (!_ready) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await repository.unregisterDevice(token);
    } catch (_) {
      // backend ลบ token ทิ้งเองเมื่อออกจากระบบทุกอุปกรณ์/เปลี่ยนรหัสผ่าน
    }
  }

  static bool _isAllowed(AuthorizationStatus status) =>
      status == AuthorizationStatus.authorized ||
      status == AuthorizationStatus.provisional;

  static void _onForegroundMessage(RemoteMessage message) {
    unawaited(NotificationCenter.refreshUnread());
    final notification = message.notification;
    final text = [
      notification?.title,
      notification?.body,
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join('\n');
    if (text.isEmpty) return;

    final recipeId = message.data['recipeId'];
    appScaffoldMessengerKey.currentState?.showAppSnackBar(
      text,
      action: recipeId is String && recipeId.isNotEmpty
          ? SnackBarAction(
              label: appL10n.notificationOpen,
              onPressed: () => _openFromPush(message),
            )
          : null,
    );
  }

  static void _openFromPush(RemoteMessage message) {
    final notificationId = message.data['notificationId'];
    if (notificationId is String && notificationId.isNotEmpty) {
      unawaited(NotificationCenter.markRead(notificationId));
    }
    final recipeId = message.data['recipeId'];
    if (recipeId is! String || recipeId.isEmpty) return;
    appNavigatorKey.currentState?.push(
      notificationRecipeRoute(
        recipeId,
        AppNotificationType.parse(message.data['type']),
      ),
    );
  }
}
