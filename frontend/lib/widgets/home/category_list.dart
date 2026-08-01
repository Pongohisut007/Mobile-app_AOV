import 'package:flutter/material.dart';

import 'category_item.dart';

class CategoryList extends StatelessWidget {
  const CategoryList({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: const [
          CategoryItem(icon: Icons.lunch_dining, title: "Burger"),

          CategoryItem(icon: Icons.set_meal, title: "Chicken"),

          CategoryItem(icon: Icons.fastfood, title: "Fries"),

          CategoryItem(icon: Icons.local_drink, title: "Drink"),

          CategoryItem(icon: Icons.icecream, title: "Dessert"),
        ],
      ),
    );
  }
}