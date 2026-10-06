import 'package:flutter/material.dart';
import 'package:flutter_application_1/l10n/l10n.dart';
import 'package:flutter_application_1/widgets/common/auth_style.dart';

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
            style: const TextStyle(color: AuthStyle.muted),
            children: [
              TextSpan(text: context.l10n.signUp, style: AuthStyle.linkStyle),
            ],
          ),
        ),
      ),
    );
  }
}
