import 'package:flutter/material.dart';
import 'package:flutter_application_1/l10n/l10n.dart';
import 'package:flutter_application_1/widgets/common/auth_style.dart';

class RegisterFormFields extends StatelessWidget {
  const RegisterFormFields({
    required this.displayNameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onSubmitted,
    super.key,
  });

  final TextEditingController displayNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(l10n.displayName),
        const SizedBox(height: 9),
        TextFormField(
          controller: displayNameController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.nickname, AutofillHints.name],
          decoration: AuthStyle.input(l10n.displayNameHint),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return l10n.displayNameRequired;
            }
            if (value.trim().length > 150) {
              return l10n.displayNameTooLong;
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        _label(l10n.emailAddress),
        const SizedBox(height: 9),
        TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email, AutofillHints.username],
          autocorrect: false,
          decoration: AuthStyle.input(l10n.emailHint),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return l10n.emailRequired;
            }
            if (!AuthStyle.isEmail(value)) return l10n.emailInvalid;
            return null;
          },
        ),
        const SizedBox(height: 20),
        _label(l10n.password),
        const SizedBox(height: 9),
        _passwordField(
          context,
          controller: passwordController,
          obscureText: obscurePassword,
          hint: l10n.passwordHint,
          // บอกเงื่อนไขตั้งแต่แรก ไม่ต้องรอกดสมัครแล้วเจอ error
          helper: l10n.passwordLengthHelper,
          onToggle: onTogglePassword,
          onSubmitted: null,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.passwordRequired;
            }
            if (value.length < AuthStyle.minPasswordLength) {
              return l10n.passwordTooShort;
            }
            if (value.length > AuthStyle.maxPasswordLength) {
              return l10n.passwordTooLong;
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        _label(l10n.confirmPassword),
        const SizedBox(height: 9),
        _passwordField(
          context,
          controller: confirmPasswordController,
          obscureText: obscureConfirmPassword,
          hint: l10n.confirmPasswordHint,
          onToggle: onToggleConfirmPassword,
          onSubmitted: onSubmitted,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.confirmPasswordRequired;
            }
            if (value != passwordController.text) {
              return l10n.passwordsDoNotMatch;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AuthStyle.label,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _passwordField(
    BuildContext context, {
    required TextEditingController controller,
    required bool obscureText,
    required String hint,
    String? helper,
    required VoidCallback onToggle,
    required VoidCallback? onSubmitted,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: onSubmitted == null
          ? TextInputAction.next
          : TextInputAction.done,
      // ให้ password manager เสนอรหัสผ่านใหม่ที่เดายาก
      autofillHints: const [AutofillHints.newPassword],
      decoration: AuthStyle.input(hint, helper: helper).copyWith(
        suffixIcon: IconButton(
          tooltip: obscureText
              ? context.l10n.showPassword
              : context.l10n.hidePassword,
          onPressed: onToggle,
          icon: Icon(
            obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: const Color(0xFF777777),
          ),
        ),
      ),
      validator: validator,
      onFieldSubmitted: onSubmitted == null ? null : (_) => onSubmitted(),
    );
  }
}
