import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_form_section_heading.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_form_style.dart';
import 'package:flutter_application_1/l10n/l10n.dart';

class RecipeTypeSection extends StatelessWidget {
  const RecipeTypeSection({
    super.key,
    required this.type,
    required this.onTypeChanged,
  });

  final String type;
  final ValueChanged<String> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return RecipeFormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RecipeFormSectionHeading(
            title: context.l10n.recipeType,
            subtitle: context.l10n.recipeTypeSubtitle,
            icon: Icons.storefront_rounded,
          ),

          const SizedBox(height: 16),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              RecipeChoiceChip(
                label: context.l10n.recipeTypeOfficial,
                icon: Icons.sell_outlined,
                selected: type == 'official',
                onSelected: () => onTypeChanged('official'),
              ),
              RecipeChoiceChip(
                label: context.l10n.recipeTypeCommunity,
                icon: Icons.groups_2_outlined,
                selected: type == 'community',
                onSelected: () => onTypeChanged('community'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
