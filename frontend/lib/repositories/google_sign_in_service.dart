import 'package:flutter_application_1/config/google_config.dart';
import 'package:flutter_application_1/l10n/l10n.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// ขอ ID token จาก Google ให้ backend ตรวจ (POST /auth/google)
abstract interface class GoogleIdTokenProvider {
  /// เปิดหน้าเลือกบัญชี Google แล้วคืน ID token
  /// ผู้ใช้ปิด/ยกเลิกเอง = null (ไม่ใช่ error)
  Future<String?> signIn();

  /// ออกจากบัญชี Google ในแอป ครั้งหน้าจะได้เลือกบัญชีใหม่
  Future<void> signOut();
}

/// client ID อ่านจาก [GoogleConfig] (ค่าเริ่มต้นในโค้ด ส่ง --dart-define ทับได้)
/// ไม่ได้ตั้ง = ปุ่ม Google แจ้งว่ายังไม่เปิดใช้
class GoogleSignInService implements GoogleIdTokenProvider {
  GoogleSignInService._();

  static final instance = GoogleSignInService._();

  static const _serverClientId = GoogleConfig.serverClientId;
  static const _iosClientId = GoogleConfig.iosClientId;

  bool get isConfigured => _serverClientId.isNotEmpty;

  // initialize เรียกได้ครั้งเดียวตลอดอายุแอป
  Future<void>? _initialization;

  Future<void> _initialize() {
    return _initialization ??= GoogleSignIn.instance.initialize(
      clientId: _iosClientId.isEmpty ? null : _iosClientId,
      serverClientId: _serverClientId,
    );
  }

  @override
  Future<String?> signIn() async {
    if (!isConfigured) throw Exception(appL10n.googleSignInUnavailable);
    try {
      await _initialize();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) throw Exception(appL10n.googleSignInFailed);
      return idToken;
    } on GoogleSignInException catch (error) {
      // ผู้ใช้ปิดหน้าต่างเลือกบัญชีเอง ไม่ต้องแจ้ง error
      if (error.code == GoogleSignInExceptionCode.canceled ||
          error.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      throw Exception(appL10n.googleSignInFailed);
    }
  }

  @override
  Future<void> signOut() async {
    if (!isConfigured || _initialization == null) return;
    try {
      await _initialization;
      await GoogleSignIn.instance.signOut();
    } on Object {
      // ออกจากระบบของแอปสำเร็จแล้ว ฝั่ง Google พลาดก็ไม่เป็นไร
    }
  }
}
