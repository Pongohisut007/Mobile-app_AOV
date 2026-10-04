import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_form_section_heading.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_form_style.dart';

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

  static const _difficulties = [
    ('easy', 'ง่าย', Icons.sentiment_satisfied_alt_rounded),
    ('medium', 'ปานกลาง', Icons.local_fire_department_outlined),
    ('hard', 'ยาก', Icons.whatshot_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return RecipeFormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const RecipeFormSectionHeading(
            title: 'รายละเอียดสูตร',
            subtitle: 'เวลา จำนวนที่เสิร์ฟ และความยาก',
            icon: Icons.tune_rounded,
          ),

          const SizedBox(height: 18),

          if (showPrice) ...[
            TextFormField(
              controller: priceController,
              decoration: RecipeFormStyle.input(
                label: 'ราคา',
                prefixText: '฿ ',
                suffixText: 'บาท',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: preparationController,
                  decoration: RecipeFormStyle.input(
                    label: 'เตรียม',
                    suffixText: 'นาที',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      requiredWholeNumber(value, 'เวลาเตรียม'),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: TextFormField(
                  controller: cookingController,
                  decoration: RecipeFormStyle.input(
                    label: 'ปรุง',
                    suffixText: 'นาที',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => requiredWholeNumber(value, 'เวลาปรุง'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          TextFormField(
            controller: servingsController,
            decoration: RecipeFormStyle.input(
              label: 'จำนวนที่รับประทาน',
              suffixText: 'ที่',
              prefixIcon: const Icon(
                Icons.people_alt_outlined,
                color: RecipeFormStyle.muted,
              ),
            ),
            keyboardType: TextInputType.number,
            validator: (value) =>
                requiredWholeNumber(value, 'จำนวนที่รับประทาน'),
          ),

          const SizedBox(height: 16),

          const Text(
            'ระดับความยาก',
            style: TextStyle(
              color: RecipeFormStyle.ink,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          // ชิปแทน dropdown แต่ยังเป็น FormField เพื่อให้ตรวจ "เลือกระดับความยาก" ได้
          FormField<String>(
            // ค่าเปลี่ยนจากข้างนอก (เช่นโหลดสูตรเดิม) ให้ FormField รับค่าใหม่
            key: ValueKey(difficulty),
            initialValue: difficulty,
            validator: (value) => value == null ? 'เลือกระดับความยาก' : null,
            builder: (field) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (value, label, icon) in _difficulties)
                      RecipeChoiceChip(
                        label: label,
                        icon: icon,
                        selected: field.value == value,
                        onSelected: () {
                          field.didChange(value);
                          onDifficultyChanged(value);
                        },
                      ),
                  ],
                ),
                if (field.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      field.errorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
