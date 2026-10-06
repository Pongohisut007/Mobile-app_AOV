import 'dart:async';

import 'package:flutter_application_1/data/user_cache.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';

/// จุดเดียวที่จัดการ "session หมดอายุ" ทั้งแอป
///
/// คำขอที่แนบ token ไปแล้ว backend ตอบ 401 (token หมดอายุ/ออกจากระบบจากที่อื่น/บัญชีถูกลบ)
/// → ล้าง token และข้อมูลของบัญชีนี้ในเครื่อง แล้วแจ้งทาง [events]
/// ให้ทุกหน้ากลับเป็นผู้เยี่ยมชม (มีปุ่มเข้าสู่ระบบ) แทนที่จะ error วนอยู่
abstract final class SessionExpiry {
  static final _events = StreamController<void>.broadcast();

  /// เกิดขึ้นหลังล้าง session แล้ว
  static Stream<void> get events => _events.stream;

  static Future<bool>? _pending;

  /// [token] = token ที่ส่งไปแล้วได้ 401
  /// คืน true ถ้าล้าง session ไปแล้ว (หรือไม่มี session อยู่แล้ว)
  ///
  /// ไม่ใช่ token ที่ใช้อยู่ตอนนี้ (คำขอเก่าค้างมาหลัง login ใหม่) = ไม่ทำอะไร
  /// หลายคำขอได้ 401 พร้อมกัน = จัดการครั้งเดียว
  static Future<bool> report(String token, {TokenStorage? storage}) {
    return _pending ??= _handle(
      token.trim(),
      storage ?? TokenStorage(),
    ).whenComplete(() => _pending = null);
  }

  static Future<bool> _handle(String token, TokenStorage storage) async {
    final current = (await storage.readAccessToken())?.trim();
    if (current == null || current.isEmpty) return true;
    if (current != token) return false;

    await storage.clearSession();
    clearUserCaches();
    _events.add(null);
    return true;
  }
}
