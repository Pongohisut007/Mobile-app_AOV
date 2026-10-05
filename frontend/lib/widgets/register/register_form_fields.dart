import 'package:flutter/material.dart';
import 'package:flutter_application_1/l10n/l10n.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(context.l10n.displayName),
        const SizedBox(height: 9),
        TextFormField(
          controller: displayNameController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: _decoration(context.l10n.displayNameHint),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return context.l10n.displayNameRequired;
            }
            if (value.trim().length > 150) {
              return context.l10n.displayNameTooLong;
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        _label(context.l10n.emailAddress),
        const SizedBox(height: 9),
        TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: _decoration(context.l10n.emailHint),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return context.l10n.emailRequired;
            }
            if (!value.contains('@')) return context.l10n.emailInvalid;
            return null;
          },
        ),
        const SizedBox(height: 20),
        _label(context.l10n.password),
        const SizedBox(height: 9),
        _passwordField(
          context,
          controller: passwordController,
          obscureText: obscurePassword,
          hint: context.l10n.passwordHint,
          onToggle: onTogglePassword,
          onSubmitted: null,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return context.l10n.passwordRequired;
            }
            if (value.length < 8) {
              return context.l10n.passwordTooShort;
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        _label(context.l10n.confirmPassword),
        const SizedBox(height: 9),
        _passwordField(
          context,
          controller: confirmPasswordController,
          obscureText: obscureConfirmPassword,
          hint: context.l10n.confirmPasswordHint,
          onToggle: onToggleConfirmPassword,
          onSubmitted: onSubmitted,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return context.l10n.confirmPasswordRequired;
            }
            if (value != passwordController.text) {
              return context.l10n.passwordsDoNotMatch;
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
        color: Color(0xFF303030),
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
    required VoidCallback onToggle,
    required VoidCallback? onSubmitted,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: TextInputAction.done,
      decoration: _decoration(hint).copyWith(
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

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
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
