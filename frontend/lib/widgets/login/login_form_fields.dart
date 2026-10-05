import 'package:flutter/material.dart';
import 'package:flutter_application_1/l10n/l10n.dart';

class LoginFormFields extends StatelessWidget {
  const LoginFormFields({
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.onSubmitted,
    super.key,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmitted;

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
          decoration: _inputDecoration(context.l10n.emailHint),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return context.l10n.emailRequired;
            }
            if (!value.contains('@')) {
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
          decoration: _inputDecoration(context.l10n.passwordHint).copyWith(
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
            if (value.length < 8) {
              return context.l10n.passwordTooShort;
            }
            return null;
          },
          onFieldSubmitted: (_) => onSubmitted(),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
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

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFFB8B8B8), fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      enabledBorder: _border(const Color(0xFFE3E3E3)),
      focusedBorder: _border(const Color(0xFFF20D13), width: 1.5),
      errorBorder: _border(Colors.red),
      focusedErrorBorder: _border(Colors.red, width: 1.5),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: BorderSide(color: color, width: width),
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
        color: Color(0xFF303030),
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
