import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/profile/profile_bloc.dart';
import 'package:flutter_application_1/bloc/profile/profile_event.dart';
import 'package:flutter_application_1/bloc/profile/profile_state.dart';
import 'package:flutter_application_1/models/user_profile.dart';
import 'package:flutter_application_1/models/recipe_collection_type.dart';
import 'package:flutter_application_1/models/recipe_summary.dart';
import 'package:flutter_application_1/repositories/category_repository.dart';
import 'package:flutter_application_1/views/pages/create_foodcard_page.dart';
import 'package:flutter_application_1/views/pages/food_detail_page.dart';
import 'package:flutter_application_1/widgets/common/app_snack_bar.dart';
import 'package:flutter_application_1/widgets/profile/profile_extras.dart';
import 'package:flutter_application_1/routes/app_routes.dart';
import 'package:flutter_application_1/views/pages/edit_profile_page.dart';
import 'package:flutter_application_1/views/pages/settings_page.dart';
import 'package:flutter_application_1/widgets/profile/profile_widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/l10n/l10n.dart';

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<ProfileBloc>();
    final completed = bloc.stream.firstWhere(
      (state) => state is ProfileLoaded || state is ProfileFailure,
    );
    bloc.add(const ProfileRefreshRequested());
    await completed;
  }

  // ยังไม่เข้าสู่ระบบก็เปิดได้ (เปลี่ยนภาษา/ดูนโยบาย) แต่ซ่อนเมนูที่ต้องมีบัญชี
  void _openSettings(BuildContext context, {bool isSignedIn = true}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsPage(isSignedIn: isSignedIn),
      ),
    );
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

  void _openRecipe(BuildContext context, RecipeSummary recipe) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FoodDetailPage(foodsId: recipe.id),
      ),
    );
  }

  // ปุ่ม "แบ่งปันสูตรแรก": creator เริ่มที่สูตร official ส่วน user เริ่มที่ community
  Future<void> _createRecipe(BuildContext context, UserProfile profile) async {
    final profileBloc = context.read<ProfileBloc>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      // หน้าสร้างสูตรต้องมีรายการหมวดหมู่ทั้งหมดให้เลือก
      final categories = await CategoryRepository().fetchCategories();
      final created = await navigator.push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => CreateFoodcardPage(
            categories: categories,
            isFromCommunity: !profile.isCreator,
          ),
        ),
      );
      if (created == true) profileBloc.add(const ProfileRefreshRequested());
    } catch (error) {
      messenger.showAppSnackBar(
        l10n.openEditorFailed('$error'),
        type: AppSnackType.error,
      );
    }
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
                onRecipeCollectionPressed: (collectionType) =>
                    _openRecipeCollection(context, collectionType),
                onCartPressed: () => _openCart(context),
                onOpenRecipe: (recipe) => _openRecipe(context, recipe),
                onCreateRecipe: () => _createRecipe(context, profile),
              ),
              ProfileGuest() => _ProfileContent(
                profile: UserProfile.guest(),
                onRefresh: () async {},
                onEditProfile: () =>
                    Navigator.pushNamed(context, AppRoutes.login),
                onSettingsPressed: () =>
                    _openSettings(context, isSignedIn: false),
                onRecipeCollectionPressed: (_) =>
                    Navigator.pushNamed(context, AppRoutes.login),
                onCartPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.login),
                onOpenRecipe: (_) =>
                    Navigator.pushNamed(context, AppRoutes.login),
                onCreateRecipe: () =>
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
    required this.onRecipeCollectionPressed,
    required this.onCartPressed,
    required this.onOpenRecipe,
    required this.onCreateRecipe,
    this.isGuest = false,
  });

  final UserProfile profile;
  final RefreshCallback onRefresh;
  final VoidCallback onEditProfile;
  final VoidCallback onSettingsPressed;
  final ValueChanged<RecipeCollectionType> onRecipeCollectionPressed;
  final VoidCallback onCartPressed;
  final ValueChanged<RecipeSummary> onOpenRecipe;
  final VoidCallback onCreateRecipe;
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
                  actionLabel: isGuest
                      ? context.l10n.signIn
                      : context.l10n.editProfile,
                  actionIcon: isGuest
                      ? Icons.login_rounded
                      : Icons.edit_outlined,
                ),
                // ผู้เยี่ยมชมยังไม่มีผลงานให้แสดง
                if (!isGuest) ...[
                  const SizedBox(height: 16),
                  ProfileStatsRow(profile: profile),
                ],
                const SizedBox(height: 24),
                ProfileSectionTitle(title: context.l10n.yourKitchenTitle),
                const SizedBox(height: 12),
                ProfileQuickActions(
                  profile: profile,
                  onPressed: onRecipeCollectionPressed,
                ),
                if (!isGuest && ProfileNudgeCard.hasContent(profile)) ...[
                  const SizedBox(height: 14),
                  ProfileNudgeCard(
                    profile: profile,
                    onOpenDrafts: () =>
                        onRecipeCollectionPressed(RecipeCollectionType.drafts),
                    onCreateRecipe: onCreateRecipe,
                  ),
                ],
                if (!isGuest && profile.purchasedCount > 0) ...[
                  const SizedBox(height: 24),
                  // ซื้อเพิ่ม/ดึงรีเฟรชแล้วจำนวนเปลี่ยน = โหลดรายการใหม่
                  RecentPurchasesSection(
                    key: ValueKey(profile.purchasedCount),
                    onOpenRecipe: onOpenRecipe,
                    onSeeAll: () => onRecipeCollectionPressed(
                      RecipeCollectionType.purchased,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
