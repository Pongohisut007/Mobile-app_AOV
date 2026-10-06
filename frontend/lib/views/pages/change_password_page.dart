import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/repositories/auth_repository.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_application_1/widgets/common/app_snack_bar.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_form_style.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';
import 'package:flutter_application_1/l10n/l10n.dart';

/// เปลี่ยนรหัสผ่าน: ยืนยันรหัสเดิม + รหัสใหม่ 2 ครั้ง
/// ยังไม่เคยมีรหัสผ่าน (สมัครผ่าน Google) = "ตั้งรหัสผ่าน" ไม่มีช่องรหัสเดิม
/// สำเร็จแล้ว pop กลับพร้อม true
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key, this.hasPassword = true});

  final bool hasPassword;

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  final _repository = HttpAuthRepository(baseUrl: ApiConfig.apiBaseUrl);

  bool _isSaving = false;
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isSaving = true);
    try {
      final token = await TokenStorage().readAccessToken();
      if (token == null || token.trim().isEmpty) {
        throw AuthRepositoryException(appL10n.sessionExpired);
      }
      final response = await _repository.changePassword(
        accessToken: token,
        currentPassword: widget.hasPassword ? _currentController.text : null,
        newPassword: _newController.text,
      );
      // token ใบเดิมใช้ไม่ได้แล้ว (เครื่องอื่นหลุด) เก็บใบใหม่ไว้ให้เครื่องนี้ใช้ต่อ
      await TokenStorage().saveSession(
        accessToken: response.accessToken,
        userId: response.user.id,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AuthRepositoryException catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showAppSnackBar(context, error.message, type: AppSnackType.error);
    }
  }

  String _title(BuildContext context) => widget.hasPassword
      ? context.l10n.changePassword
      : context.l10n.setPassword;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSaving,
      child: Scaffold(
        backgroundColor: ProfileColors.background,
        appBar: RecipeFormStyle.appBar(title: _title(context)),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _isSaving ? null : _submit,
            style: RecipeFormStyle.primaryButton().copyWith(
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.disabled)
                    ? ProfileColors.ink.withValues(alpha: 0.35)
                    : ProfileColors.ink,
              ),
              foregroundColor: const WidgetStatePropertyAll(Colors.white),
            ),
            icon: _isSaving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.lock_reset_rounded),
            label: Text(_isSaving ? context.l10n.saving : _title(context)),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              RecipeFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.hasPassword) ...[
                      _PasswordField(
                        controller: _currentController,
                        label: context.l10n.currentPassword,
                        visible: _showCurrent,
                        enabled: !_isSaving,
                        onToggle: () =>
                            setState(() => _showCurrent = !_showCurrent),
                        validator: (value) => (value == null || value.isEmpty)
                            ? context.l10n.currentPasswordRequired
                            : null,
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      Text(
                        context.l10n.setPasswordHint,
                        style: const TextStyle(
                          color: ProfileColors.muted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _PasswordField(
                      controller: _newController,
                      label: context.l10n.newPassword,
                      helperText: context.l10n.passwordLengthHelper,
                      visible: _showNew,
                      enabled: !_isSaving,
                      onToggle: () => setState(() => _showNew = !_showNew),
                      // กติกาเดียวกับตอนสมัคร
                      validator: (value) {
                        final password = value ?? '';
                        if (password.length < 8) {
                          return context.l10n.passwordTooShort;
                        }
                        if (password.length > 72) {
                          return context.l10n.passwordTooLong;
                        }
                        if (widget.hasPassword &&
                            password == _currentController.text) {
                          return context.l10n.newPasswordSameAsOld;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _PasswordField(
                      controller: _confirmController,
                      label: context.l10n.confirmNewPassword,
                      visible: _showConfirm,
                      enabled: !_isSaving,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      onToggle: () =>
                          setState(() => _showConfirm = !_showConfirm),
                      validator: (value) => value != _newController.text
                          ? context.l10n.newPasswordsDoNotMatch
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.visible,
    required this.enabled,
    required this.onToggle,
    required this.validator,
    this.helperText,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final bool visible;
  final bool enabled;
  final VoidCallback onToggle;
  final FormFieldValidator<String> validator;
  final String? helperText;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: !visible,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      decoration:
          RecipeFormStyle.input(
            label: label,
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: RecipeFormStyle.muted,
            ),
          ).copyWith(
            helperText: helperText,
            suffixIcon: IconButton(
              onPressed: onToggle,
              tooltip: visible
                  ? context.l10n.hidePassword
                  : context.l10n.showPassword,
              color: RecipeFormStyle.muted,
              icon: Icon(
                visible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
    );
  }
}
