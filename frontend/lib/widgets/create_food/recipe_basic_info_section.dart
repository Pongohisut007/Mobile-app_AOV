import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_form_section_heading.dart';

class RecipeBasicInfoSection extends StatelessWidget {
  const RecipeBasicInfoSection({
    super.key,
    required this.titleController,
    required this.slugController,
    required this.descriptionController,
    required this.validator,
  });

  final TextEditingController titleController;
  final TextEditingController slugController;
  final TextEditingController descriptionController;

  final String? Function(String?, String) validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RecipeFormSectionHeading(
          title: 'สูตรของคุณ',
          icon: Icons.menu_book_outlined,
        ),
        const SizedBox(height: 14),

        TextFormField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'ชื่อภาษาไทย',
            border: OutlineInputBorder(),
          ),
          validator: (value) => validator(value, 'ชื่อสูตรอาหาร'),
          textCapitalization: TextCapitalization.words,
        ),

        const SizedBox(height: 12),

        TextFormField(
          controller: slugController,
          decoration: const InputDecoration(
            labelText: 'ชื่อภาษาอังกฤษ',
            hintText: 'spicy-basil-chicken',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            final required = validator(value, 'slug');

            if (required != null) {
              return required;
            }

            if (!RegExp(
              r'^[a-z0-9]+(?:-[a-z0-9]+)*$',
            ).hasMatch(value!.trim())) {
              return 'ใช้ a-z, 0-9 และเครื่องหมาย - เท่านั้น';
            }

            return null;
          },
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp('[a-z0-9-]'),
            ),
          ],
        ),

        const SizedBox(height: 12),

        TextFormField(
          controller: descriptionController,
          decoration: const InputDecoration(
            labelText: 'คำอธิบาย',
            hintText: 'เล่าจุดเด่นหรือรสชาติของเมนูนี้',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 3,
        ),
      ],
    );
  }
}