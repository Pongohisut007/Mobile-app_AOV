import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/common/app_shadows.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/config/app_info.dart';
import 'package:flutter_application_1/content/app_texts.dart';
import 'package:flutter_application_1/data/session.dart';
import 'package:flutter_application_1/repositories/auth_repository.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_application_1/views/pages/change_password_page.dart';
import 'package:flutter_application_1/views/pages/delete_account_page.dart';
import 'package:flutter_application_1/views/pages/text_sections_page.dart';
import 'package:flutter_application_1/widgets/common/app_snack_bar.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_form_style.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';

/// ตั้งค่า: บัญชี / ความช่วยเหลือ / เกี่ยวกับแอป / ออกจากระบบ / ลบบัญชี
/// (ปุ่ม Sign out มีที่นี่ที่เดียว)
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

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
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const ChangePasswordPage()),
    );
    if (changed != true) return;
    messenger.showAppSnackBar(
      'เปลี่ยนรหัสผ่านแล้ว อุปกรณ์อื่นถูกออกจากระบบ',
      type: AppSnackType.success,
    );
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
    bool danger = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: danger ? _danger : ProfileColors.ink,
            ),
            child: Text(action),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _signOut() async {
    final confirmed = await _confirm(
      title: 'Sign out?',
      message: 'You can sign back in at any time to access your recipes.',
      action: 'Sign out',
    );
    if (!confirmed || !mounted) return;
    await signOutLocally(context);
  }

  Future<void> _logoutAllDevices() async {
    if (_isLoggingOutAll) return;
    final confirmed = await _confirm(
      title: 'ออกจากระบบทุกอุปกรณ์?',
      message:
          'ทุกเครื่องที่เข้าสู่ระบบด้วยบัญชีนี้ รวมถึงเครื่องนี้ จะถูกออกจากระบบทันที',
      action: 'ออกจากระบบทั้งหมด',
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

  void _openAbout() {
    showAboutDialog(
      context: context,
      applicationName: AppInfo.name,
      applicationVersion: 'Version ${AppInfo.version}',
      applicationLegalese: '© ${DateTime.now().year} ${AppInfo.name}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfileColors.background,
      appBar: RecipeFormStyle.appBar(title: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const _SectionLabel('บัญชี'),
          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.lock_reset_rounded,
                label: 'เปลี่ยนรหัสผ่าน',
                onTap: _openChangePassword,
              ),
              _SettingsTile(
                icon: Icons.devices_other_rounded,
                label: 'ออกจากระบบทุกอุปกรณ์',
                subtitle: 'ใช้เมื่อมือถือหาย หรือสงสัยว่ามีคนใช้บัญชี',
                isLoading: _isLoggingOutAll,
                onTap: _logoutAllDevices,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionLabel('ความช่วยเหลือและข้อกำหนด'),
          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.help_outline_rounded,
                label: 'Help & support',
                onTap: () => _push(const HelpSupportPage()),
              ),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                label: 'นโยบายความเป็นส่วนตัว',
                onTap: () => _push(
                  const TextSectionsPage(
                    title: 'นโยบายความเป็นส่วนตัว',
                    sections: privacySections,
                  ),
                ),
              ),
              _SettingsTile(
                icon: Icons.description_outlined,
                label: 'ข้อกำหนดการใช้งาน',
                onTap: () => _push(
                  const TextSectionsPage(
                    title: 'ข้อกำหนดการใช้งาน',
                    sections: termsSections,
                  ),
                ),
              ),
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                label: 'เกี่ยวกับแอป',
                subtitle: 'เวอร์ชัน ${AppInfo.version} · ไลเซนส์โอเพนซอร์ส',
                onTap: _openAbout,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.logout_rounded,
                label: 'Sign out',
                foregroundColor: _danger,
                showChevron: false,
                onTap: _signOut,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionLabel('โซนอันตราย'),
          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.delete_forever_outlined,
                label: 'ลบบัญชี',
                subtitle: 'ปิดบัญชีและลบข้อมูลส่วนตัว กู้คืนไม่ได้',
                foregroundColor: _danger,
                onTap: () => _push(const DeleteAccountPage()),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              '${AppInfo.name} · Version ${AppInfo.version}',
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
