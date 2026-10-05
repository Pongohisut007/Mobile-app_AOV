import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/common/app_shadows.dart';
import 'package:flutter_application_1/models/recipe_collection_type.dart';
import 'package:flutter_application_1/models/user_profile.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';
import 'package:flutter_application_1/l10n/l10n.dart';

class ProfileQuickActions extends StatelessWidget {
  const ProfileQuickActions({
    super.key,
    required this.profile,
    required this.onPressed,
  });

  final UserProfile profile;
  final ValueChanged<RecipeCollectionType> onPressed;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: [
        _QuickActionCard(
          label: context.l10n.myRecipes,
          detail: context.l10n.myRecipesDetail(profile.recipeCount),
          icon: Icons.restaurant_menu_rounded,
          color: const Color(0xFFFFE6CC),
          onTap: () => onPressed(RecipeCollectionType.myRecipes),
        ),
        _QuickActionCard(
          label: context.l10n.purchasedRecipes,
          detail: context.l10n.purchasedDetail(profile.purchasedCount),
          icon: Icons.receipt_long_rounded,
          color: const Color(0xFFE4EDFF),
          onTap: () => onPressed(RecipeCollectionType.purchased),
        ),
        _QuickActionCard(
          label: context.l10n.favorites,
          detail: context.l10n.favoritesDetail(profile.savedCount),
          icon: Icons.favorite_rounded,
          color: const Color(0xFFFFE2E8),
          onTap: () => onPressed(RecipeCollectionType.favorites),
        ),
        _QuickActionCard(
          label: context.l10n.drafts,
          detail: context.l10n.draftsDetail(profile.draftCount),
          icon: Icons.edit_note_rounded,
          color: const Color(0xFFE8F3D7),
          onTap: () => onPressed(RecipeCollectionType.drafts),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.label,
    required this.detail,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String detail;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ShadowBox(
      borderRadius: BorderRadius.circular(22),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: ProfileColors.ink, size: 21),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ProfileColors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ProfileColors.muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
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
