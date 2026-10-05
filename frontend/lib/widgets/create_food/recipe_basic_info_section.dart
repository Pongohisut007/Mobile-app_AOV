import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_form_section_heading.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_form_style.dart';
import 'package:flutter_application_1/l10n/l10n.dart';

class RecipeBasicInfoSection extends StatelessWidget {
  const RecipeBasicInfoSection({
    super.key,
    required this.titleController,
    required this.titleEnController,
    required this.descriptionController,
    required this.validator,
  });

  final TextEditingController titleController;
  final TextEditingController titleEnController;
  final TextEditingController descriptionController;

  final String? Function(String?, String) validator;

  @override
  Widget build(BuildContext context) {
    return RecipeFormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RecipeFormSectionHeading(
            title: context.l10n.yourRecipe,
            subtitle: context.l10n.yourRecipeSubtitle,
            icon: Icons.menu_book_rounded,
          ),
          const SizedBox(height: 18),

          TextFormField(
            controller: titleController,
            decoration: RecipeFormStyle.input(
              label: context.l10n.thaiName,
              hint: context.l10n.thaiNameHint,
            ),
            validator: (value) =>
                validator(value, context.l10n.recipeNameField),
            textCapitalization: TextCapitalization.words,
          ),

          const SizedBox(height: 12),

          TextFormField(
            controller: titleEnController,
            decoration: RecipeFormStyle.input(
              label: context.l10n.englishName,
              hint: context.l10n.englishNameHint,
            ).copyWith(helperText: context.l10n.englishNameHelper),
            maxLength: 255,
            textCapitalization: TextCapitalization.sentences,
          ),

          const SizedBox(height: 12),

          TextFormField(
            controller: descriptionController,
            decoration: RecipeFormStyle.input(
              label: context.l10n.descriptionField,
              hint: context.l10n.descriptionHint,
              alignLabelWithHint: true,
            ),
            minLines: 3,
            maxLines: 5,
          ),
        ],
      ),
    );
  }
}
