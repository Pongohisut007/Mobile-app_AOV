import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/l10n/l10n.dart';
import 'package:flutter_application_1/models/recipe_collection_type.dart';
import 'package:flutter_application_1/models/recipe_summary.dart';
import 'package:flutter_application_1/models/user_profile.dart';
import 'package:flutter_application_1/repositories/recipe_library_repository.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_application_1/widgets/common/app_shadows.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';
import 'package:flutter_application_1/widgets/profile/profile_section_title.dart';
import 'package:flutter_application_1/widgets/recipe_library/recipe_library_card.dart';

/// การ์ดชวนทำต่อบนหน้าโปรไฟล์
/// - มีฉบับร่าง = ชวนเขียนต่อ (เปิดคลังฉบับร่าง)
/// - ยังไม่เคยเผยแพร่สูตร = ชวนลงสูตรแรก
/// - นอกนั้นไม่แสดง
class ProfileNudgeCard extends StatelessWidget {
  const ProfileNudgeCard({
    super.key,
    required this.profile,
    required this.onOpenDrafts,
    required this.onCreateRecipe,
  });

  final UserProfile profile;
  final VoidCallback onOpenDrafts;
  final VoidCallback onCreateRecipe;

  /// มีอะไรให้แสดงไหม (หน้าโปรไฟล์ใช้เว้นระยะ)
  static bool hasContent(UserProfile profile) =>
      profile.draftCount > 0 || profile.recipeCount == 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (icon, title, subtitle, onTap) = profile.draftCount > 0
        ? (
            Icons.edit_note_rounded,
            l10n.continueDraftTitle,
            l10n.continueDraftSubtitle(profile.draftCount),
            onOpenDrafts,
          )
        : (
            Icons.add_circle_outline_rounded,
            l10n.firstRecipeTitle,
            profile.isCreator
                ? l10n.firstRecipeSubtitleCreator
                : l10n.firstRecipeSubtitleUser,
            onCreateRecipe,
          );
    if (!hasContent(profile)) return const SizedBox.shrink();

    return ShadowBox(
      borderRadius: BorderRadius.circular(22),
      child: Material(
        color: ProfileColors.ink,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: ProfileColors.accent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "ซื้อล่าสุด": การ์ดสูตรที่ซื้อล่าสุดเลื่อนแนวนอน กดเปิดสูตรได้เลย
/// โหลดใหม่เมื่อจำนวนที่ซื้อเปลี่ยน (หน้าโปรไฟล์ส่ง key ตาม purchasedCount)
/// โหลดไม่ได้ = ซ่อนทั้งส่วน ไม่ต้องขึ้น error บนหน้าโปรไฟล์
class RecentPurchasesSection extends StatefulWidget {
  const RecentPurchasesSection({
    super.key,
    required this.onOpenRecipe,
    required this.onSeeAll,
    this.repository,
    this.tokenStorage,
  });

  static const maxItems = 5;

  final ValueChanged<RecipeSummary> onOpenRecipe;
  final VoidCallback onSeeAll;
  final RecipeLibraryRepository? repository;
  final TokenStorage? tokenStorage;

  @override
  State<RecentPurchasesSection> createState() => _RecentPurchasesSectionState();
}

class _RecentPurchasesSectionState extends State<RecentPurchasesSection> {
  late final Future<List<RecipeSummary>> _recipes = _load();

  Future<List<RecipeSummary>> _load() async {
    final storage = widget.tokenStorage ?? TokenStorage();
    final userId = await storage.readUserId();
    final token = await storage.readAccessToken();
    if (userId == null || token == null) return const [];
    final repository =
        widget.repository ??
        HttpRecipeLibraryRepository(baseUrl: ApiConfig.apiBaseUrl);
    final page = await repository.fetchCollectionPage(
      RecipeCollectionType.purchased,
      userId: userId,
      accessToken: token,
    );
    return page.items.take(RecentPurchasesSection.maxItems).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RecipeSummary>>(
      future: _recipes,
      builder: (context, snapshot) {
        final recipes = snapshot.data;
        final isLoading = snapshot.connectionState != ConnectionState.done;
        if (!isLoading && (recipes == null || recipes.isEmpty)) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProfileSectionTitle(
              title: context.l10n.recentPurchases,
              actionLabel: context.l10n.seeMore,
              onAction: widget.onSeeAll,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: _cardHeight,
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: ProfileColors.ink,
                      ),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      // เผื่อที่ให้เงาการ์ดไม่ขาด
                      clipBehavior: Clip.none,
                      itemCount: recipes!.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final recipe = recipes[index];
                        return SizedBox(
                          width: _cardWidth,
                          child: RecipeLibraryCard(
                            recipe: recipe,
                            onTap: () => widget.onOpenRecipe(recipe),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  static const double _cardWidth = 160;
  static const double _cardHeight = 250;
}
