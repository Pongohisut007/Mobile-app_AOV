import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/profile/profile_bloc.dart';
import 'package:flutter_application_1/bloc/profile/profile_event.dart';
import 'package:flutter_application_1/bloc/profile/profile_state.dart';
import 'package:flutter_application_1/models/user_profile.dart';
import 'package:flutter_application_1/models/recipe_collection_type.dart';
import 'package:flutter_application_1/routes/app_routes.dart';
import 'package:flutter_application_1/views/pages/edit_profile_page.dart';
import 'package:flutter_application_1/views/pages/settings_page.dart';
import 'package:flutter_application_1/views/pages/text_sections_page.dart';
import 'package:flutter_application_1/config/app_info.dart';
import 'package:flutter_application_1/widgets/common/app_snack_bar.dart';
import 'package:flutter_application_1/widgets/profile/profile_widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  void _showComingSoon(BuildContext context, String feature) {
    showAppSnackBar(context, '$feature is coming soon');
  }

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<ProfileBloc>();
    final completed = bloc.stream.firstWhere(
      (state) => state is ProfileLoaded || state is ProfileFailure,
    );
    bloc.add(const ProfileRefreshRequested());
    await completed;
  }

  void _openSettings(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SettingsPage()));
  }

  void _openCart(BuildContext context) {
    // ซื้อสูตรจากตะกร้าแล้ว ตัวเลข "ซื้อแล้ว" บนโปรไฟล์ต้องอัปเดต
    final profileBloc = context.read<ProfileBloc>();
    Navigator.pushNamed(context, AppRoutes.cart).then((_) {
      profileBloc.add(const ProfileRefreshRequested());
    });
  }

  void _openRecipeCollection(
    BuildContext context,
    RecipeCollectionType collectionType,
  ) {
    final routeName = switch (collectionType) {
      RecipeCollectionType.myRecipes => AppRoutes.myRecipes,
      RecipeCollectionType.purchased => AppRoutes.purchasedRecipes,
      RecipeCollectionType.favorites => AppRoutes.favoriteRecipes,
      RecipeCollectionType.drafts => AppRoutes.draftRecipes,
    };
    // ในคลังสูตรอาจลบ/สร้าง/เผยแพร่สูตร หรือเลิกกดหัวใจ
    // กลับมาแล้วอัปเดตตัวเลขบนโปรไฟล์เงียบ ๆ (โชว์ตัวเลขเดิมไว้ระหว่างโหลด)
    final profileBloc = context.read<ProfileBloc>();
    Navigator.pushNamed(context, routeName).then((_) {
      profileBloc.add(const ProfileRefreshRequested());
    });
  }

  // หน้าแก้โปรไฟล์คืนโปรไฟล์ใหม่มา (ยกเลิก = null) แสดงได้ทันทีไม่ต้องโหลดซ้ำ
  Future<void> _openEditProfile(
    BuildContext context,
    UserProfile profile,
  ) async {
    final profileBloc = context.read<ProfileBloc>();
    final updated = await Navigator.of(context).push<UserProfile>(
      MaterialPageRoute<UserProfile>(
        builder: (_) => EditProfilePage(profile: profile),
      ),
    );
    if (updated != null) profileBloc.add(ProfileUpdated(updated));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfileColors.background,
      body: SafeArea(
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            return switch (state) {
              ProfileLoaded(:final profile) => _ProfileContent(
                profile: profile,
                onRefresh: () => _refresh(context),
                onEditProfile: () => _openEditProfile(context, profile),
                onSettingsPressed: () => _openSettings(context),
                onActionPressed: (label) => label == 'Help & support'
                    ? Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const HelpSupportPage(),
                        ),
                      )
                    // Notifications ยังไม่มีระบบรองรับ
                    : _showComingSoon(context, label),
                onRecipeCollectionPressed: (collectionType) =>
                    _openRecipeCollection(context, collectionType),
                onCartPressed: () => _openCart(context),
              ),
              ProfileGuest() => _ProfileContent(
                profile: UserProfile.guest(),
                onRefresh: () async {},
                onEditProfile: () =>
                    Navigator.pushNamed(context, AppRoutes.login),
                onSettingsPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.login),
                onActionPressed: (_) =>
                    Navigator.pushNamed(context, AppRoutes.login),
                onRecipeCollectionPressed: (_) =>
                    Navigator.pushNamed(context, AppRoutes.login),
                onCartPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.login),
                isGuest: true,
              ),
              ProfileFailure(:final message) => ProfileErrorView(
                message: message,
                onRetry: () =>
                    context.read<ProfileBloc>().add(const ProfileRequested()),
              ),
              _ => const ProfileLoadingView(),
            };
          },
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.profile,
    required this.onRefresh,
    required this.onEditProfile,
    required this.onSettingsPressed,
    required this.onActionPressed,
    required this.onRecipeCollectionPressed,
    required this.onCartPressed,
    this.isGuest = false,
  });

  final UserProfile profile;
  final RefreshCallback onRefresh;
  final VoidCallback onEditProfile;
  final VoidCallback onSettingsPressed;
  final ValueChanged<String> onActionPressed;
  final ValueChanged<RecipeCollectionType> onRecipeCollectionPressed;
  final VoidCallback onCartPressed;
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: ProfileColors.ink,
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            sliver: SliverList.list(
              children: [
                ProfilePageHeader(
                  onSettingsPressed: onSettingsPressed,
                  onCartPressed: onCartPressed,
                ),
                const SizedBox(height: 22),
                ProfileCard(
                  profile: profile,
                  onEditPressed: onEditProfile,
                  actionLabel: isGuest ? 'Sign in' : 'Edit profile',
                  actionIcon: isGuest
                      ? Icons.login_rounded
                      : Icons.edit_outlined,
                ),
                const SizedBox(height: 16),
                ProfileStatsRow(profile: profile),
                const SizedBox(height: 30),
                const ProfileSectionTitle(
                  title: 'Your kitchen',
                  subtitle: 'Everything you cook and collect',
                ),
                const SizedBox(height: 14),
                ProfileQuickActions(
                  profile: profile,
                  onPressed: onRecipeCollectionPressed,
                ),
                const SizedBox(height: 30),
                const ProfileSectionTitle(
                  title: 'Account',
                  subtitle: 'Manage your preferences',
                ),
                const SizedBox(height: 14),
                // Sign out อยู่ในหน้า Settings ที่เดียว
                ProfileAccountMenu(onPressed: onActionPressed),
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
          ),
        ],
      ),
    );
  }
}
