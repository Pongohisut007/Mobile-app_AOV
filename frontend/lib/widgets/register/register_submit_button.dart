import 'package:flutter/material.dart';
import 'package:flutter_application_1/l10n/l10n.dart';
import 'package:flutter_application_1/widgets/common/auth_style.dart';

class RegisterSubmitButton extends StatelessWidget {
  const RegisterSubmitButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AuthPrimaryButton(label: context.l10n.signUp, onPressed: onPressed);
  }
}
