import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_form_section_heading.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_form_style.dart';

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
    final disabled = isSaving || isBusy;

    return RecipeFormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RecipeFormSectionHeading(
            title: 'ขั้นตอนการทำอาหาร',
            subtitle: hasDraft
                ? 'แตะเพื่อแก้ไขหัวข้อและขั้นตอน'
                : 'ยังไม่ได้เพิ่มหัวข้อขั้นตอน',
            icon: Icons.format_list_numbered_rounded,
          ),

          if (hasDraft) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatTile(value: '$sectionCount', label: 'ชุด'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatTile(value: '$stepCount', label: 'ขั้นตอน'),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: disabled ? null : onEdit,
              style: RecipeFormStyle.secondaryButton(height: 50),
              icon: Icon(hasDraft ? Icons.edit_rounded : Icons.add_rounded),
              label: Text(
                hasDraft ? 'แก้ไขหัวข้อขั้นตอน' : 'เพิ่มหัวข้อขั้นตอน',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: RecipeFormStyle.fieldFill,
        borderRadius: BorderRadius.circular(RecipeFormStyle.fieldRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: RecipeFormStyle.ink,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: RecipeFormStyle.muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
