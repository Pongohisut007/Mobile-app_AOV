import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/category.dart';

class CategorySelector extends StatefulWidget {
  const CategorySelector({
    super.key,
    required this.categories,
    required this.onCategorySelected,
  });

  final List<Category> categories;
  final ValueChanged<String?> onCategorySelected;

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  int? selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: widget.categories.asMap().entries.map((entry) {
              final index = entry.key;
              final category = entry.value;

              final isSelected = selectedCategory == index;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selectedCategory == index) {
                      selectedCategory = null;
                    } else {
                      selectedCategory = index;
                    }
                  });

                  final uuid = selectedCategory == null
                      ? null
                      : widget.categories[selectedCategory!].id;

                  widget.onCategorySelected(uuid);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isSelected
                            ? Colors.grey.shade700
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? Colors.black87
                          : Colors.grey,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        Container(
          height: 1,
          color: Colors.grey.shade300,
        ),
      ],
    );
  }
}
