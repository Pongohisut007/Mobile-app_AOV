import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/cart/cart_bloc.dart';
import 'package:flutter_application_1/bloc/cart/cart_event.dart';
import 'package:flutter_application_1/bloc/favorite/favorite_bloc.dart';
import 'package:flutter_application_1/bloc/favorite/favorite_event.dart';
import 'package:flutter_application_1/bloc/purchased_recipes/purchased_recipes_bloc.dart';
import 'package:flutter_application_1/bloc/purchased_recipes/purchased_recipes_event.dart';
import 'package:flutter_application_1/data/user_cache.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_application_1/routes/app_routes.dart';
import 'package:flutter_application_1/views/pages/change_password_page.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_form_style.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// ตั้งค่า: เปลี่ยนรหัสผ่าน และออกจากระบบ (ปุ่ม Sign out มีที่นี่ที่เดียว)
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _openChangePassword(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const ChangePasswordPage()),
    );
    if (changed != true) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('เปลี่ยนรหัสผ่านแล้ว')));
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    // bloc เหล่านี้อยู่เหนือ MaterialApp จึงอ่านได้จากทุกหน้า
    final cartBloc = context.read<CartBloc>();
    final favoriteBloc = context.read<FavoriteBloc>();
    final purchasedRecipesBloc = context.read<PurchasedRecipesBloc>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You can sign back in at any time to access your recipes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: ProfileColors.ink),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await TokenStorage().clearSession();
    clearUserCaches();
    // อ่าน token ไม่เจอแล้ว ทุก bloc จะล้าง state ของคนเก่าทิ้งเอง
    cartBloc.add(const CartRequested());
    favoriteBloc.add(const FavoritesRequested());
    purchasedRecipesBloc.add(const PurchasedRecipesRequested());
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
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
                onTap: () => _openChangePassword(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.logout_rounded,
                label: 'Sign out',
                foregroundColor: const Color(0xFFD54444),
                showChevron: false,
                onTap: () => _confirmSignOut(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Recipy · Version 1.0.0',
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

/// หน้าตาเดียวกับเมนูในหน้า Profile
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.foregroundColor = ProfileColors.ink,
    this.showChevron = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color foregroundColor;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
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
      trailing: showChevron
          ? Icon(
              Icons.chevron_right_rounded,
              color: foregroundColor.withValues(alpha: 0.45),
            )
          : null,
    );
  }
}
