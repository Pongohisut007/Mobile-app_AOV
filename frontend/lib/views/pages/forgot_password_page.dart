import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/l10n/l10n.dart';
import 'package:flutter_application_1/models/auth_response.dart';
import 'package:flutter_application_1/repositories/auth_repository.dart';
import 'package:flutter_application_1/widgets/common/app_snack_bar.dart';
import 'package:flutter_application_1/widgets/common/auth_style.dart';

/// ลืมรหัสผ่าน 2 ขั้นในหน้าเดียว
/// 1. กรอกอีเมล → backend ส่งรหัส 6 หลักไปทางอีเมล
/// 2. กรอกรหัส + รหัสผ่านใหม่ → สำเร็จแล้ว pop กลับพร้อม [AuthResponse]
///    (หน้า login เอาไปเข้าสู่ระบบต่อให้เลย ไม่ต้องพิมพ์รหัสใหม่ซ้ำ)
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({
    super.key,
    this.initialEmail = '',
    this.repository,
  });

  /// อีเมลที่พิมพ์ค้างไว้ในหน้า login
  final String initialEmail;

  final AuthRepository? repository;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  /// ตรงกับ RESET_CODE_RESEND_SECONDS ของ backend
  static const _resendSeconds = 60;

  late final AuthRepository _repository =
      widget.repository ?? HttpAuthRepository(baseUrl: ApiConfig.apiBaseUrl);

  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  late final _emailController = TextEditingController(
    text: widget.initialEmail.trim(),
  );
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _codeSent = false;
  bool _isLoading = false;
  bool _showPassword = false;
  String? _errorMessage;

  Timer? _resendTimer;
  int _resendIn = 0;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _resendIn = _resendSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _resendIn--);
      if (_resendIn <= 0) timer.cancel();
    });
  }

  Future<void> _sendCode({bool resend = false}) async {
    if (_isLoading) return;
    if (!resend && !_emailFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _repository.requestPasswordReset(
        email: _emailController.text,
        language: appL10n.localeName,
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _codeSent = true;
      });
      _startResendCountdown();
      if (resend) {
        showAppSnackBar(context, context.l10n.resetCodeResent);
      }
    } on AuthRepositoryException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      });
    }
  }

  Future<void> _resetPassword() async {
    if (_isLoading) return;
    if (!_resetFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await _repository.resetPassword(
        email: _emailController.text,
        code: _codeController.text,
        newPassword: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop<AuthResponse>(response);
    } on AuthRepositoryException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      });
    }
  }

  void _changeEmail() {
    _resendTimer?.cancel();
    setState(() {
      _codeSent = false;
      _errorMessage = null;
      _resendIn = 0;
      _codeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: !_isLoading,
      child: Scaffold(
        backgroundColor: AuthStyle.primary,
        body: AuthBackground(
          child: SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _Header(
                    title: _codeSent
                        ? l10n.resetPasswordTitle
                        : l10n.forgotPasswordTitle,
                    subtitle: _codeSent
                        ? l10n.resetCodeSentTo(_emailController.text.trim())
                        : l10n.forgotPasswordIntro,
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(34),
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _codeSent ? _resetForm() : _emailForm(),
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

  Widget _emailForm() {
    final l10n = context.l10n;
    return Form(
      key: _emailFormKey,
      child: Column(
        key: const ValueKey('email-step'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(l10n.emailAddress),
          const SizedBox(height: 9),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.send,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            enabled: !_isLoading,
            decoration: AuthStyle.input(l10n.emailHint),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.emailRequired;
              }
              if (!AuthStyle.isEmail(value)) return l10n.emailInvalid;
              return null;
            },
            onFieldSubmitted: (_) => _sendCode(),
          ),
          ..._error(),
          const SizedBox(height: 22),
          AuthPrimaryButton(
            label: l10n.sendResetCode,
            isLoading: _isLoading,
            onPressed: _sendCode,
          ),
        ],
      ),
    );
  }

  Widget _resetForm() {
    final l10n = context.l10n;
    return Form(
      key: _resetFormKey,
      child: AutofillGroup(
        child: Column(
          key: const ValueKey('reset-step'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FieldLabel(l10n.resetCode),
            const SizedBox(height: 9),
            TextFormField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              // Android/iOS เสนอรหัสจากอีเมล/SMS ให้กดเติมได้
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              enabled: !_isLoading,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 6,
              ),
              decoration: AuthStyle.input(l10n.resetCodeHint),
              validator: (value) => RegExp(r'^\d{6}$').hasMatch(value ?? '')
                  ? null
                  : l10n.resetCodeInvalid,
            ),
            const SizedBox(height: 18),
            _FieldLabel(l10n.newPassword),
            const SizedBox(height: 9),
            TextFormField(
              controller: _passwordController,
              obscureText: !_showPassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              enabled: !_isLoading,
              decoration:
                  AuthStyle.input(
                    l10n.passwordHint,
                    helper: l10n.passwordLengthHelper,
                  ).copyWith(
                    suffixIcon: IconButton(
                      tooltip: _showPassword
                          ? l10n.hidePassword
                          : l10n.showPassword,
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                      icon: Icon(
                        _showPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFF777777),
                      ),
                    ),
                  ),
              validator: (value) {
                final password = value ?? '';
                if (password.length < AuthStyle.minPasswordLength) {
                  return l10n.passwordTooShort;
                }
                if (password.length > AuthStyle.maxPasswordLength) {
                  return l10n.passwordTooLong;
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            _FieldLabel(l10n.confirmNewPassword),
            const SizedBox(height: 9),
            TextFormField(
              controller: _confirmController,
              obscureText: !_showPassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              enabled: !_isLoading,
              decoration: AuthStyle.input(l10n.confirmPasswordHint),
              validator: (value) => value != _passwordController.text
                  ? l10n.newPasswordsDoNotMatch
                  : null,
              onFieldSubmitted: (_) => _resetPassword(),
            ),
            ..._error(),
            const SizedBox(height: 22),
            AuthPrimaryButton(
              label: l10n.resetPasswordSubmit,
              isLoading: _isLoading,
              onPressed: _resetPassword,
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : _changeEmail,
                  style: TextButton.styleFrom(foregroundColor: AuthStyle.muted),
                  child: Text(l10n.changeEmail),
                ),
                TextButton(
                  onPressed: _isLoading || _resendIn > 0
                      ? null
                      : () => _sendCode(resend: true),
                  style: TextButton.styleFrom(
                    foregroundColor: AuthStyle.primary,
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  child: Text(
                    _resendIn > 0
                        ? l10n.resendCodeIn(_resendIn)
                        : l10n.resendCode,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _error() => [
    if (_errorMessage case final message?) ...[
      const SizedBox(height: 14),
      AuthErrorBanner(message: message),
    ],
  ];
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 24, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

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
