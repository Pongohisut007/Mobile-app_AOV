import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/auth/auth_bloc.dart';
import 'package:flutter_application_1/bloc/auth/auth_state.dart';
import 'package:flutter_application_1/widgets/common/auth_style.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/widgets/register/register_form_fields.dart';
import 'package:flutter_application_1/widgets/register/register_social_buttons.dart';
import 'package:flutter_application_1/widgets/register/register_submit_button.dart';
import 'package:flutter_application_1/widgets/register/register_terms.dart';
import 'package:flutter_application_1/l10n/l10n.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({
    required this.onSubmit,
    required this.onSignIn,
    super.key,
  });

  final void Function({
    required String email,
    required String password,
    required String displayName,
  })
  onSubmit;
  final VoidCallback onSignIn;

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;

  /// error ในฟอร์ม (ยังไม่ยอมรับข้อกำหนด / error จาก server) พิมพ์แก้แล้วหายไป
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _displayNameController,
      _emailController,
      _passwordController,
      _confirmPasswordController,
    ]) {
      controller.addListener(_clearError);
    }
  }

  void _clearError() {
    if (_errorMessage != null) setState(() => _errorMessage = null);
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    _clearError();
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedTerms) {
      setState(() => _errorMessage = context.l10n.acceptTermsRequired);
      return;
    }

    widget.onSubmit(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _displayNameController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // error จาก server (เช่น อีเมลนี้ถูกใช้แล้ว) แสดงในฟอร์มแทน snackbar
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) setState(() => _errorMessage = state.message);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RegisterFormFields(
                  displayNameController: _displayNameController,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  confirmPasswordController: _confirmPasswordController,
                  obscurePassword: _obscurePassword,
                  obscureConfirmPassword: _obscureConfirmPassword,
                  onTogglePassword: () => setState(() {
                    _obscurePassword = !_obscurePassword;
                  }),
                  onToggleConfirmPassword: () => setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  }),
                  onSubmitted: _submit,
                ),
                const SizedBox(height: 12),
                RegisterTerms(
                  accepted: _acceptedTerms,
                  onChanged: (value) => setState(() {
                    _acceptedTerms = value;
                    _errorMessage = null;
                  }),
                ),
                if (_errorMessage case final message?) ...[
                  const SizedBox(height: 12),
                  AuthErrorBanner(message: message),
                ],
                const SizedBox(height: 18),
                RegisterSubmitButton(onPressed: _submit),
                const SizedBox(height: 20),
                const RegisterSocialButtons(),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: widget.onSignIn,
                    child: Text.rich(
                      TextSpan(
                        text: context.l10n.haveAccountPrompt,
                        style: const TextStyle(color: AuthStyle.muted),
                        children: [
                          TextSpan(
                            text: context.l10n.signIn,
                            style: AuthStyle.linkStyle,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
