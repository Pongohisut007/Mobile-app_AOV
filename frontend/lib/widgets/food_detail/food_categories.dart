import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/category.dart';
import 'package:flutter_application_1/widgets/food_detail/food_detail_colors.dart';

/// ป้ายหมวดทั้งหมดของสูตร ใต้ชื่อสูตร (สูตรหนึ่งอยู่ได้หลายหมวด ยาวเกินบรรทัดก็ขึ้นบรรทัดใหม่)
class FoodCategories extends StatelessWidget {
  const FoodCategories({super.key, required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final category in categories)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const ShapeDecoration(
              color: FoodDetailColors.softPurple,
              shape: StadiumBorder(),
            ),
            child: Text(
              category.displayName(context),
              style: const TextStyle(
                color: FoodDetailColors.purple,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}
