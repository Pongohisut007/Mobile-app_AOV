sealed class AuthEvent {
  const AuthEvent();
}

final class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({required this.email, required this.password});

  final String email;
  final String password;
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
