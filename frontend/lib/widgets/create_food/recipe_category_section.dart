import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/category.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_form_section_heading.dart';

class RecipeCategorySection extends StatelessWidget {
  const RecipeCategorySection({
    super.key,
    required this.categories,
    required this.selectedCategoryIds,
    required this.onCategorySelected,
  });

  final List<Category> categories;
  final Set<String> selectedCategoryIds;
  final ValueChanged<Category> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RecipeFormSectionHeading(
          title: 'หมวดหมู่',
          icon: Icons.category_outlined,
        ),

        const SizedBox(height: 8),

        if (categories.isEmpty)
          const Text('ไม่มีหมวดหมู่ให้เลือก')
        else
          Autocomplete<Category>(
            optionsBuilder: (
              TextEditingValue textEditingValue,
            ) {
              final query = textEditingValue.text
                  .trim()
                  .toLowerCase();

              if (query.isEmpty) {
                return categories;
              }

              return categories.where(
                (category) => category.name
                    .toLowerCase()
                    .contains(query),
              );
            },

            displayStringForOption: (category) =>
                category.name,

            onSelected: onCategorySelected,

            fieldViewBuilder: (
              context,
              controller,
              focusNode,
              onFieldSubmitted,
            ) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  hintText: 'ค้นหาหมวดหมู่...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              );
            },

            optionsViewBuilder: (
              context,
              onSelected,
              options,
            ) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 180,
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final category =
                            options.elementAt(index);

                        final isSelected =
                            selectedCategoryIds
                                .contains(category.id);

                        return ListTile(
                          dense: true,
                          title: Text(category.name),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.green,
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
              );
            },
          ),
      ],
    );
  }
}