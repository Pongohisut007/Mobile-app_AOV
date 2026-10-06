import 'package:flutter/material.dart';
import 'package:flutter_application_1/l10n/l10n.dart';
import 'package:flutter_application_1/widgets/common/auth_style.dart';

class LoginSubmitButton extends StatelessWidget {
  const LoginSubmitButton({required this.onPressed, this.label, super.key});

  final VoidCallback onPressed;

  /// ไม่ส่ง = "เข้าสู่ระบบ"
  final String? label;

  @override
  Widget build(BuildContext context) {
    return AuthPrimaryButton(
      label: label ?? context.l10n.signIn,
      onPressed: onPressed,
    );
  }
}
