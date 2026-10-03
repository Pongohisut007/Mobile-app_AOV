import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_form_section_heading.dart';

class RecipeDetailSection extends StatelessWidget {
  const RecipeDetailSection({
    super.key,
    required this.priceController,
    required this.preparationController,
    required this.cookingController,
    required this.servingsController,
    required this.difficulty,
    required this.showPrice,
    required this.requiredWholeNumber,
    required this.nonNegativeNumber,
    required this.onDifficultyChanged,
  });

  final TextEditingController priceController;
  final TextEditingController preparationController;
  final TextEditingController cookingController;
  final TextEditingController servingsController;

  final String? difficulty;
  final bool showPrice;

  final String? Function(String?, String) requiredWholeNumber;
  final String? Function(String?, String) nonNegativeNumber;

  final ValueChanged<String?> onDifficultyChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RecipeFormSectionHeading(
          title: 'รายละเอียดสูตร',
          icon: Icons.tune_rounded,
        ),

        const SizedBox(height: 12),

        if (showPrice) ...[
          TextFormField(
            controller: priceController,
            decoration: const InputDecoration(
              labelText: 'ราคา (บาท)',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'กรอกราคา';
              }

              return nonNegativeNumber(value, 'ราคา');
            },
          ),

          const SizedBox(height: 12),
        ],

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: preparationController,
                decoration: const InputDecoration(
                  labelText: 'เตรียม (นาที)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    requiredWholeNumber(
                      value,
                      'เวลาเตรียม',
                    ),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: TextFormField(
                controller: cookingController,
                decoration: const InputDecoration(
                  labelText: 'ปรุง (นาที)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    requiredWholeNumber(
                      value,
                      'เวลาปรุง',
                    ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: servingsController,
                decoration: const InputDecoration(
                  labelText: 'จำนวนที่รับประทาน',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    requiredWholeNumber(
                      value,
                      'จำนวนที่รับประทาน',
                    ),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: difficulty,
                decoration: const InputDecoration(
                  labelText: 'ระดับความยาก',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null
                        ? 'เลือกระดับความยาก'
                        : null,
                items: const [
                  DropdownMenuItem(
                    value: 'easy',
                    child: Text('ง่าย'),
                  ),
                  DropdownMenuItem(
                    value: 'medium',
                    child: Text('ปานกลาง'),
                  ),
                  DropdownMenuItem(
                    value: 'hard',
                    child: Text('ยาก'),
                  ),
                ],
                onChanged: onDifficultyChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}