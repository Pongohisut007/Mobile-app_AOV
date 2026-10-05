import 'package:flutter/material.dart';
import 'package:flutter_application_1/l10n/l10n.dart';

class LoginFooter extends StatelessWidget {
  const LoginFooter({this.onSignUp, super.key});

  final VoidCallback? onSignUp;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onSignUp,
        child: Text.rich(
          TextSpan(
            text: context.l10n.noAccountPrompt,
            style: TextStyle(color: Color(0xFF8A8A8A)),
            children: [
              TextSpan(
                text: context.l10n.signUp,
                style: TextStyle(
                  color: Color(0xFFF20D13),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
