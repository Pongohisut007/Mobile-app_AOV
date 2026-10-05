import 'package:flutter/material.dart';
import 'package:flutter_application_1/l10n/l10n.dart';
import 'package:flutter_application_1/widgets/common/auth_style.dart';

class LoginFormFields extends StatelessWidget {
  const LoginFormFields({
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.onSubmitted,
    this.onForgotPassword,
    super.key,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmitted;
  final VoidCallback? onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: context.l10n.emailAddress),
        const SizedBox(height: 9),
        TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          // ให้ password manager เติม/บันทึกบัญชีได้
          autofillHints: const [AutofillHints.email, AutofillHints.username],
          autocorrect: false,
          decoration: AuthStyle.input(context.l10n.emailHint),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return context.l10n.emailRequired;
            }
            if (!AuthStyle.isEmail(value)) {
              return context.l10n.emailInvalid;
            }
            return null;
          },
        ),
        const SizedBox(height: 22),
        _FieldLabel(label: context.l10n.password),
        const SizedBox(height: 9),
        TextFormField(
          controller: passwordController,
          obscureText: obscurePassword,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          decoration: AuthStyle.input(context.l10n.passwordHint).copyWith(
            suffixIcon: IconButton(
              tooltip: obscurePassword
                  ? context.l10n.showPassword
                  : context.l10n.hidePassword,
              onPressed: onTogglePassword,
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF777777),
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return context.l10n.passwordRequired;
            }
            if (value.length < AuthStyle.minPasswordLength) {
              return context.l10n.passwordTooShort;
            }
            if (value.length > AuthStyle.maxPasswordLength) {
              return context.l10n.passwordTooLong;
            }
            return null;
          },
          onFieldSubmitted: (_) => onSubmitted(),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onForgotPassword,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF777777),
              padding: const EdgeInsets.only(top: 4),
            ),
            child: Text(context.l10n.forgotPassword),
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AuthStyle.label,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
