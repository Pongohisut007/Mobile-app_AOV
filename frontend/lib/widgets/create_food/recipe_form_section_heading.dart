import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_form_style.dart';

/// หัวของแต่ละการ์ดในฟอร์ม: ไอคอนในกรอบส้มอ่อน + หัวข้อ + คำอธิบายสั้น ๆ
class RecipeFormSectionHeading extends StatelessWidget {
  const RecipeFormSectionHeading({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: RecipeFormStyle.accentSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 21, color: RecipeFormStyle.accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: RecipeFormStyle.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: RecipeFormStyle.muted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
