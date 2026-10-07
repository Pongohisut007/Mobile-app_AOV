import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/data/push_notifications.dart';
import 'package:flutter_application_1/repositories/notification_repository.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';

/// จำนวนแจ้งเตือนที่ยังไม่อ่าน (ตัวเลขบนกระดิ่ง) ใช้ร่วมกันทั้งแอป
/// อัปเดตตอน: เปิดแอป, กลับมาที่แอป, login/logout, ได้ push ขณะเปิดแอป, อ่านรายการ
abstract final class NotificationCenter {
  static NotificationRepository repository = HttpNotificationRepository(
    baseUrl: ApiConfig.apiBaseUrl,
  );
  static TokenStorage storage = TokenStorage();

  static final unreadCount = ValueNotifier<int>(0);

  static AppLifecycleListener? _lifecycle;
  static String? _userId;

  /// เรียกครั้งเดียวหลัง runApp (ต้องรู้ว่าใคร login อยู่แล้ว)
  static void start() {
    _userId = TokenStorage.currentUserId.value;
    TokenStorage.currentUserId.addListener(_onAccountChanged);
    _lifecycle ??= AppLifecycleListener(onResume: refreshUnread);
    if (_userId != null) {
      unawaited(refreshUnread());
      unawaited(PushNotifications.syncDevice());
    }
  }

  // login / สลับบัญชี / logout / session หมดอายุ ผ่าน TokenStorage ทั้งหมด
  static void _onAccountChanged() {
    final userId = TokenStorage.currentUserId.value;
    if (userId == _userId) return;
    _userId = userId;
    if (userId == null) {
      unreadCount.value = 0;
      // เครื่องนี้ไม่ใช่ของบัญชีนั้นแล้ว ไม่ต้องได้ push ของบัญชีนั้นอีก
      unawaited(PushNotifications.unregisterDevice());
    } else {
      unawaited(refreshUnread());
      unawaited(PushNotifications.syncDevice());
    }
  }

  static Future<void> refreshUnread() async {
    final token = (await storage.readAccessToken())?.trim();
    if (token == null || token.isEmpty) {
      unreadCount.value = 0;
      return;
    }
    try {
      unreadCount.value = await repository.fetchUnreadCount(token);
    } catch (_) {
      // ไม่มีเน็ต: คงตัวเลขเดิมไว้ ครั้งหน้าค่อยอัปเดต
    }
  }

  /// อ่านไปแล้ว [count] รายการ (ลดตัวเลขทันทีไม่ต้องรอ API)
  static void markedRead([int count = 1]) {
    unreadCount.value = math.max(0, unreadCount.value - count);
  }

  static void markedAllRead() => unreadCount.value = 0;

  /// อ่านรายการเดียว (เช่น กด push) แจ้ง backend แบบไม่รอผล
  static Future<void> markRead(String notificationId) async {
    final token = (await storage.readAccessToken())?.trim();
    if (token == null || token.isEmpty) return;
    try {
      await repository.markRead(token, notificationId);
      await refreshUnread();
    } catch (_) {}
  }
}
