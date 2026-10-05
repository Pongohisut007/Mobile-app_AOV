import 'package:flutter_application_1/models/auth_response.dart';

sealed class AuthEvent {
  const AuthEvent();
}

final class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({required this.email, required this.password});

  final String email;
  final String password;
}

/// ได้ session มาจากทางอื่นแล้ว (ตั้งรหัสผ่านใหม่ในหน้าลืมรหัสผ่านสำเร็จ)
/// บันทึกลงเครื่องแล้วถือว่าเข้าสู่ระบบ เหมือน login ปกติ
final class AuthSessionStarted extends AuthEvent {
  const AuthSessionStarted(this.response);

  final AuthResponse response;
}

/// กดปุ่ม "เข้าสู่ระบบด้วย Google" (ทั้งหน้า login และ register)
final class AuthGoogleRequested extends AuthEvent {
  const AuthGoogleRequested();
}

final class AuthRegisterRequested extends AuthEvent {
  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.displayName,
  });

  final String email;
  final String password;
  final String displayName;
}
