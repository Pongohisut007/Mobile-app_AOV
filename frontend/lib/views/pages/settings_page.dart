import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/common/app_shadows.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/config/app_info.dart';
import 'package:flutter_application_1/content/app_texts.dart';
import 'package:flutter_application_1/data/session.dart';
import 'package:flutter_application_1/repositories/auth_repository.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_application_1/routes/app_routes.dart';
import 'package:flutter_application_1/views/pages/change_password_page.dart';
import 'package:flutter_application_1/views/pages/delete_account_page.dart';
import 'package:flutter_application_1/views/pages/text_sections_page.dart';
import 'package:flutter_application_1/widgets/common/app_snack_bar.dart';
import 'package:flutter_application_1/widgets/common/language_picker.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_form_style.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';
import 'package:flutter_application_1/l10n/l10n.dart';
import 'package:flutter_application_1/widgets/common/app_dialog.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// ตั้งค่า: ภาษา / บัญชี / ความช่วยเหลือ / เกี่ยวกับแอป / ออกจากระบบ / ลบบัญชี
/// (ปุ่ม Sign out มีที่นี่ที่เดียว)
/// ยังไม่เข้าสู่ระบบก็เปิดได้ แต่ซ่อนเมนูที่ต้องมีบัญชี และมีปุ่มเข้าสู่ระบบแทนออกจากระบบ
class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    this.isSignedIn = true,
    this.hasPassword = true,
  });

  final bool isSignedIn;

  /// false = สมัครผ่าน Google และยังไม่มีรหัสผ่าน (เมนูเป็น "ตั้งรหัสผ่าน")
  final bool hasPassword;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _danger = Color(0xFFD54444);

  bool _isLoggingOutAll = false;

  void _push(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Future<void> _openChangePassword() async {
    final messenger = ScaffoldMessenger.of(context);
    final message = widget.hasPassword
        ? context.l10n.passwordChangedOthersSignedOut
        : context.l10n.passwordSet;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ChangePasswordPage(hasPassword: widget.hasPassword),
      ),
    );
    if (changed != true) return;
    messenger.showAppSnackBar(message, type: AppSnackType.success);
  }

  Future<bool> _confirm({
    required IconData icon,
    required String title,
    required String message,
    required String action,
    bool danger = false,
  }) {
    return showAppConfirmDialog(
      context,
      icon: icon,
      title: title,
      message: message,
      confirmLabel: action,
      cancelLabel: context.l10n.cancel,
      danger: danger,
    );
  }

  Future<void> _signOut() async {
    final confirmed = await _confirm(
      icon: Icons.logout_rounded,
      title: context.l10n.signOutConfirmTitle,
      message: context.l10n.signOutConfirmMessage,
      action: context.l10n.signOut,
    );
    if (!confirmed || !mounted) return;
    await signOutLocally(context);
  }

  Future<void> _logoutAllDevices() async {
    if (_isLoggingOutAll) return;
    final confirmed = await _confirm(
      icon: Icons.devices_other_rounded,
      title: context.l10n.signOutAllTitle,
      message: context.l10n.signOutAllMessage,
      action: context.l10n.signOutAllAction,
      danger: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isLoggingOutAll = true);
    try {
      final token = await TokenStorage().readAccessToken();
      if (token != null && token.trim().isNotEmpty) {
        await HttpAuthRepository(
          baseUrl: ApiConfig.apiBaseUrl,
        ).logoutAll(accessToken: token);
      }
      if (!mounted) return;
      await signOutLocally(context);
    } on AuthRepositoryException catch (error) {
      if (!mounted) return;
      setState(() => _isLoggingOutAll = false);
      showAppSnackBar(context, error.message, type: AppSnackType.error);
    }
  }

  // แทน showAboutDialog ของ Material (หน้าตาไม่เข้ากับแอป) ยังเปิดหน้าใบอนุญาตได้เหมือนเดิม
  void _openAbout() {
    final material = MaterialLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AppDialog(
        leading: SvgPicture.asset(
          'assets/images/recipy-logo.svg',
          width: 96,
          height: 96,
        ),
        title: AppInfo.name,
        message:
            '${context.l10n.versionLabel(AppInfo.version)}\n'
            '© ${DateTime.now().year} ${AppInfo.name}',
        actions: [
          AppDialogButton(
            label: material.closeButtonLabel,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          AppDialogButton(
            label: material.viewLicensesButtonLabel,
            style: AppDialogActionStyle.text,
            onPressed: () {
              Navigator.of(dialogContext).pop();
              showLicensePage(
                context: context,
                applicationName: AppInfo.name,
                applicationVersion: AppInfo.version,
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfileColors.background,
      appBar: RecipeFormStyle.appBar(title: context.l10n.settingsTitle),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _SectionLabel(context.l10n.settingsGeneral),
          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.translate_rounded,
                label: context.l10n.language,
                subtitle: AppLanguage.nativeName(AppLanguage.current),
                onTap: () => showLanguagePicker(context),
              ),
            ],
          ),
          if (widget.isSignedIn) ...[
            const SizedBox(height: 20),
            _SectionLabel(context.l10n.settingsAccount),
            _SettingsGroup(
              children: [
                _SettingsTile(
                  icon: Icons.lock_reset_rounded,
                  label: widget.hasPassword
                      ? context.l10n.changePassword
                      : context.l10n.setPassword,
                  onTap: _openChangePassword,
                ),
                _SettingsTile(
                  icon: Icons.devices_other_rounded,
                  label: context.l10n.signOutAllDevices,
                  subtitle: context.l10n.signOutAllDevicesHint,
                  isLoading: _isLoggingOutAll,
                  onTap: _logoutAllDevices,
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          _SectionLabel(context.l10n.settingsHelpAndTerms),
          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.help_outline_rounded,
                label: context.l10n.helpAndSupport,
                onTap: () => _push(const HelpSupportPage()),
              ),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                label: context.l10n.privacyPolicy,
                onTap: () => _push(
                  TextSectionsPage(
                    title: context.l10n.privacyPolicy,
                    sections: privacySections(context.l10n),
                  ),
                ),
              ),
              _SettingsTile(
                icon: Icons.description_outlined,
                label: context.l10n.termsOfUse,
                onTap: () => _push(
                  TextSectionsPage(
                    title: context.l10n.termsOfUse,
                    sections: termsSections(context.l10n),
                  ),
                ),
              ),
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                label: context.l10n.aboutApp,
                subtitle: context.l10n.aboutAppSubtitle(AppInfo.version),
                onTap: _openAbout,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsGroup(
            children: [
              widget.isSignedIn
                  ? _SettingsTile(
                      icon: Icons.logout_rounded,
                      label: context.l10n.signOut,
                      foregroundColor: _danger,
                      showChevron: false,
                      onTap: _signOut,
                    )
                  : _SettingsTile(
                      icon: Icons.login_rounded,
                      label: context.l10n.signIn,
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.login),
                    ),
            ],
          ),
          if (widget.isSignedIn) ...[
            const SizedBox(height: 20),
            _SectionLabel(context.l10n.dangerZone),
            _SettingsGroup(
              children: [
                _SettingsTile(
                  icon: Icons.delete_forever_outlined,
                  label: context.l10n.deleteAccount,
                  subtitle: context.l10n.deleteAccountHint,
                  foregroundColor: _danger,
                  onTap: () =>
                      _push(DeleteAccountPage(hasPassword: widget.hasPassword)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          Center(
            child: Text(
              context.l10n.appVersionFooter(AppInfo.name, AppInfo.version),
              style: TextStyle(
                color: ProfileColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 10),
      child: Text(
        text,
        style: const TextStyle(
          color: ProfileColors.muted,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ShadowBox(
      borderRadius: BorderRadius.circular(24),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (final (index, child) in children.indexed) ...[
              if (index > 0)
                const Divider(height: 1, indent: 70, endIndent: 16),
              child,
            ],
          ],
        ),
      ),
    );
  }
}

/// หน้าตาเดียวกับเมนูในหน้า Profile
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.foregroundColor = ProfileColors.ink,
    this.showChevron = true,
    this.isLoading = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color foregroundColor;
  final bool showChevron;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: isLoading ? null : onTap,
      minTileHeight: 58,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: foregroundColor.withValues(alpha: 0.07),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: foregroundColor, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: const TextStyle(color: ProfileColors.muted, fontSize: 12),
            ),
      trailing: isLoading
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ProfileColors.ink,
              ),
            )
          : showChevron
          ? Icon(
              Icons.chevron_right_rounded,
              color: foregroundColor.withValues(alpha: 0.45),
            )
          : null,
    );
  }
}
