import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/common/app_shadows.dart';
import 'package:flutter_application_1/widgets/common/app_network_image.dart';
import 'package:flutter_application_1/models/recipe_summary.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';
import 'package:flutter_application_1/l10n/l10n.dart';

class RecipeLibraryCard extends StatelessWidget {
  const RecipeLibraryCard({
    super.key,
    required this.recipe,
    required this.onTap,
  });

  final RecipeSummary recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ShadowBox(
      borderRadius: BorderRadius.circular(22),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _RecipeImage(url: recipe.coverImageUrl),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: ProfileColors.ink,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          recipe.type.toUpperCase(),
                          style: TextStyle(
                            color: ProfileColors.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.categories.isEmpty
                          ? 'RECIPE'
                          : recipe.categories.first
                                .displayName(context)
                                .toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ProfileColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      recipe.displayTitle(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ProfileColors.ink,
                        fontSize: 15,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      recipe.price == 0
                          ? context.l10n.priceFree
                          : '฿${recipe.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: ProfileColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
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

class _RecipeImage extends StatelessWidget {
  const _RecipeImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;
    if (imageUrl == null) return const _ImagePlaceholder();

    return AppNetworkImage(
      imageUrl,
      placeholder: const ColoredBox(color: Color(0xFFE8E9E2)),
      errorBuilder: (context) => const _ImagePlaceholder(),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFE8E9E2),
      child: Center(
        child: Icon(
          Icons.restaurant_menu_rounded,
          color: ProfileColors.muted,
          size: 42,
        ),
      ),
    );
  }
}
