import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// ค่าโปรเจกต์ Firebase (ใช้แค่ Cloud Messaging สำหรับ push)
/// อยู่ใน config/*.json เหมือนค่าอื่น ไม่ต้องมีไฟล์ google-services.json / GoogleService-Info.plist
/// เอาค่าจาก Firebase Console → Project settings → Your apps
/// ไม่ได้ตั้ง = แอปไม่ขอรับ push (กล่องแจ้งเตือนในแอปยังใช้ได้ปกติ)
abstract final class FirebaseConfig {
  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _senderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const _androidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
  );
  static const _iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const _iosBundleId = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');

  /// ค่าของแพลตฟอร์มที่รันอยู่ null = ไม่ได้ตั้ง/แพลตฟอร์มนี้ไม่รองรับ push
  static FirebaseOptions? get currentPlatform {
    if (kIsWeb || _apiKey.isEmpty || _projectId.isEmpty || _senderId.isEmpty) {
      return null;
    }
    final appId = switch (defaultTargetPlatform) {
      TargetPlatform.android => _androidAppId,
      TargetPlatform.iOS => _iosAppId,
      _ => '',
    };
    if (appId.isEmpty) return null;
    return FirebaseOptions(
      apiKey: _apiKey,
      appId: appId,
      messagingSenderId: _senderId,
      projectId: _projectId,
      iosBundleId: _iosBundleId.isEmpty ? null : _iosBundleId,
    );
  }
}
