import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_form_section_heading.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RecipeFormSectionHeading(
          title: 'ประเภทสูตร',
          icon: Icons.storefront_outlined,
        ),

        const SizedBox(height: 8),

        DropdownButtonFormField<String>(
          initialValue: type,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(
              value: 'official',
              child: Text('Official (ขาย)'),
            ),
            DropdownMenuItem(
              value: 'community',
              child: Text('Community (ฟรี)'),
            ),
          ],
          onChanged: (value) {
            if (value != null) onTypeChanged(value);
          },
        ),
      ],
    );
  }
}
