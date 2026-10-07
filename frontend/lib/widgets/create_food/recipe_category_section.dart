import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/category.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_form_section_heading.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_form_style.dart';
import 'package:flutter_application_1/l10n/l10n.dart';

class RecipeCategorySection extends StatelessWidget {
  const RecipeCategorySection({
    super.key,
    required this.categories,
    required this.selectedCategoryIds,
    required this.onCategorySelected,
    this.onCategoryRemoved,
  });

  final List<Category> categories;
  final Set<String> selectedCategoryIds;
  final ValueChanged<Category> onCategorySelected;

  /// แตะ x บนชิปหมวดที่เลือกไว้ (null = ลบไม่ได้)
  final ValueChanged<Category>? onCategoryRemoved;

  @override
  Widget build(BuildContext context) {
    final selected = categories
        .where((category) => selectedCategoryIds.contains(category.id))
        .toList();

    return RecipeFormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RecipeFormSectionHeading(
            title: context.l10n.categories,
            subtitle: selected.isEmpty
                ? context.l10n.categoriesPickMany
                : context.l10n.categoriesSelected(selected.length),
            icon: Icons.category_rounded,
          ),

          const SizedBox(height: 16),

          if (categories.isEmpty)
            Text(
              context.l10n.noCategories,
              style: TextStyle(color: RecipeFormStyle.muted),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) => Autocomplete<Category>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  final query = textEditingValue.text.trim().toLowerCase();

                  if (query.isEmpty) {
                    return categories;
                  }

                  return categories.where(
                    (category) => category.matches(query),
                  );
                },

                displayStringForOption: (category) =>
                    category.displayName(context),

                onSelected: onCategorySelected,

                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        // แตะที่อื่น = ปิดรายการโดยไม่เลือก และล้างคำค้นที่ค้างไว้
                        onTapOutside: (_) {
                          focusNode.unfocus();
                          controller.clear();
                        },
                        decoration: RecipeFormStyle.input(
                          hint: context.l10n.searchCategoriesHint,
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: RecipeFormStyle.muted,
                          ),
                        ),
                      );
                    },

                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Material(
                        elevation: 6,
                        shadowColor: Colors.black26,
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        clipBehavior: Clip.antiAlias,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: 220,
                            maxWidth: constraints.maxWidth,
                          ),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final category = options.elementAt(index);
                              final isSelected = selectedCategoryIds.contains(
                                category.id,
                              );

                              return ListTile(
                                dense: true,
                                title: Text(
                                  category.displayName(context),
                                  style: TextStyle(
                                    color: RecipeFormStyle.ink,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(
                                        Icons.check_circle_rounded,
                                        color: RecipeFormStyle.primary,
                                      )
                                    : null,
                                onTap: () {
                                  onSelected(category);
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          if (selected.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in selected)
                  _SelectedCategoryChip(
                    label: category.displayName(context),
                    onRemove: onCategoryRemoved == null
                        ? null
                        : () => onCategoryRemoved!(category),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SelectedCategoryChip extends StatelessWidget {
  const _SelectedCategoryChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(14, 8, onRemove == null ? 14 : 6, 8),
      decoration: const ShapeDecoration(
        color: RecipeFormStyle.ink,
        shape: StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: onRemove,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.close_rounded, size: 16, color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
