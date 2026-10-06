import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// เก็บ session ของคนที่ล็อกอินไว้ข้ามการเปิดแอป
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const accessTokenKey = 'jwt_access_token';

  // เก็บ userId คู่กับ token ไว้ด้วย จะได้ไม่ต้องรอ /auth/me ตอนเปิดแอป
  static const userIdKey = 'auth_user_id';

  final FlutterSecureStorage _storage;

  /// id ของคนที่ login อยู่ (null = ยังไม่ login) อ่านได้ทันทีตอน build
  /// เช่น ซ่อนปุ่มซื้อบนการ์ดสูตรของตัวเอง โหลดค่าแรกด้วย [loadCurrentUser] ตอนเปิดแอป
  static final currentUserId = ValueNotifier<String?>(null);

  static Future<void> loadCurrentUser({TokenStorage? storage}) async {
    final userId = await (storage ?? TokenStorage()).readUserId();
    currentUserId.value = (userId == null || userId.trim().isEmpty)
        ? null
        : userId;
  }

  Future<void> saveSession({
    required String accessToken,
    required String userId,
  }) async {
    await _storage.write(key: accessTokenKey, value: accessToken);
    await _storage.write(key: userIdKey, value: userId);
    currentUserId.value = userId;
  }

  Future<String?> readAccessToken() {
    return _storage.read(key: accessTokenKey);
  }

  Future<String?> readUserId() {
    return _storage.read(key: userIdKey);
  }

  Future<void> clearSession() async {
    await _storage.delete(key: accessTokenKey);
    await _storage.delete(key: userIdKey);
    currentUserId.value = null;
  }
}
