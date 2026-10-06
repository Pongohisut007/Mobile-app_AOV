import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/data/session.dart';
import 'package:flutter_application_1/repositories/auth_repository.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_application_1/widgets/common/app_snack_bar.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_form_style.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';
import 'package:flutter_application_1/l10n/l10n.dart';

/// ลบบัญชี: อธิบายผลที่จะเกิด + ยืนยันรหัสผ่าน + ติ๊กยอมรับ
/// บัญชีที่ไม่มีรหัสผ่าน (สมัครผ่าน Google) ยืนยันด้วยการติ๊กอย่างเดียว
class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key, this.hasPassword = true});

  final bool hasPassword;

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  static const _danger = Color(0xFFD54444);

  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _repository = HttpAuthRepository(baseUrl: ApiConfig.apiBaseUrl);

  bool _confirmed = false;
  bool _showPassword = false;
  bool _isDeleting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_isDeleting || !_confirmed) return;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isDeleting = true);
    try {
      final token = await TokenStorage().readAccessToken();
      if (token == null || token.trim().isEmpty) {
        throw AuthRepositoryException(appL10n.sessionExpired);
      }
      await _repository.deleteAccount(
        accessToken: token,
        password: widget.hasPassword ? _passwordController.text : null,
      );
      if (!mounted) return;
      await signOutLocally(context);
    } on AuthRepositoryException catch (error) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      showAppSnackBar(context, error.message, type: AppSnackType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDeleting,
      child: Scaffold(
        backgroundColor: ProfileColors.background,
        appBar: RecipeFormStyle.appBar(title: context.l10n.deleteAccount),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _isDeleting || !_confirmed ? null : _delete,
            style: RecipeFormStyle.primaryButton().copyWith(
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.disabled)
                    ? _danger.withValues(alpha: 0.35)
                    : _danger,
              ),
              foregroundColor: const WidgetStatePropertyAll(Colors.white),
            ),
            icon: _isDeleting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.delete_forever_rounded),
            label: Text(
              _isDeleting
                  ? context.l10n.deletingAccount
                  : context.l10n.deleteAccountPermanently,
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _danger.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: _danger),
                        SizedBox(width: 8),
                        Text(
                          context.l10n.deleteIrreversible,
                          style: TextStyle(
                            color: _danger,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    _Bullet(context.l10n.deleteBulletSignOut),
                    _Bullet(context.l10n.deleteBulletPersonalData),
                    _Bullet(context.l10n.deleteBulletRecipes),
                    _Bullet(context.l10n.deleteBulletLibrary),
                    _Bullet(context.l10n.deleteBulletComments),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              RecipeFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // บัญชีที่ไม่มีรหัสผ่าน (สมัครผ่าน Google) ยืนยันด้วยการติ๊กอย่างเดียว
                    if (widget.hasPassword) ...[
                      TextFormField(
                        controller: _passwordController,
                        enabled: !_isDeleting,
                        obscureText: !_showPassword,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration:
                            RecipeFormStyle.input(
                              label: context.l10n.confirmWithPassword,
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                color: RecipeFormStyle.muted,
                              ),
                            ).copyWith(
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                  () => _showPassword = !_showPassword,
                                ),
                                tooltip: _showPassword
                                    ? context.l10n.hidePassword
                                    : context.l10n.showPassword,
                                color: RecipeFormStyle.muted,
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                        validator: (value) => (value == null || value.isEmpty)
                            ? context.l10n.passwordEnter
                            : null,
                      ),
                      const SizedBox(height: 8),
                    ],
                    CheckboxListTile(
                      value: _confirmed,
                      onChanged: _isDeleting
                          ? null
                          : (value) =>
                                setState(() => _confirmed = value ?? false),
                      activeColor: _danger,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        context.l10n.deleteUnderstand,
                        style: const TextStyle(
                          color: ProfileColors.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•  ',
            style: TextStyle(color: ProfileColors.ink, height: 1.45),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: ProfileColors.ink,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
