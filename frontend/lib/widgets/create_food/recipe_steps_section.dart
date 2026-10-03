import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_form_section_heading.dart';

class RecipeStepsSection extends StatelessWidget {
  const RecipeStepsSection({
    super.key,
    required this.sectionCount,
    required this.stepCount,
    required this.hasDraft,
    required this.isBusy,
    required this.isSaving,
    required this.onEdit,
  });

  final int sectionCount;
  final int stepCount;
  final bool hasDraft;
  final bool isBusy;
  final bool isSaving;

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RecipeFormSectionHeading(
          title: 'ขั้นตอนการทำอาหาร',
          icon: Icons.restaurant_menu_rounded,
        ),

        const SizedBox(height: 12),

        Text(
          hasDraft
              ? '$sectionCount ชุด · $stepCount ขั้นตอน'
              : 'ยังไม่ได้เพิ่มหัวข้อขั้นตอน',
          style: TextStyle(
            color: Colors.grey.shade700,
          ),
        ),

        const SizedBox(height: 8),

        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: isSaving || isBusy
                ? null
                : onEdit,
            icon: Icon(
              hasDraft
                  ? Icons.edit_outlined
                  : Icons.add,
            ),
            label: Text(
              hasDraft
                  ? 'แก้ไขหัวข้อขั้นตอน'
                  : 'เพิ่มหัวข้อขั้นตอน',
            ),
          ),
        ),
      ],
    );
  }
}