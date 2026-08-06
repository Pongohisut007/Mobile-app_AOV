import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/bloc/category/category_bloc.dart';
import 'package:flutter_application_1/bloc/category/category_state.dart';
import 'package:flutter_application_1/bloc/food/food_bloc.dart';
import 'package:flutter_application_1/bloc/food/food_event.dart';

import 'category_item.dart';

class CategoryList extends StatelessWidget {
  const CategoryList({super.key});

  static const Map<String, IconData> _icons = {
    'noodles': Icons.ramen_dining, 
    'made-to-order': Icons.restaurant, 
    'fire-chiken': Icons.fastfood, 
    'good-food': Icons.eco, 
    'spicy-thai-salad': Icons.local_fire_department, 
    'bubble-tea': Icons.emoji_food_beverage, 
    'dipping-sauce': Icons.water_drop, 
    'grill': Icons.outdoor_grill, 
    'thai-food': Icons.rice_bowl,
  };

  static IconData _iconFor(String slug) =>
      _icons[slug.trim().toLowerCase()] ?? Icons.restaurant_menu;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CategoryBloc, CategoryState>(
      listenWhen: (previous, current) =>
          previous.selectedSlug != current.selectedSlug,
      listener: (context, state) {
        context.read<FoodBloc>().add(
          FetchFoodByCategoryEvent(state.selectedSlug), 
        );
      },
      builder: (context, state) {
        if (state.isLoading && state.categories.isEmpty) {
          return const SizedBox(
            height: 90,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.error != null && state.categories.isEmpty) {
          return SizedBox(
            height: 90,
            child: Center(child: Text(state.error!)),
          );
        }

        return SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: state.categories.length,
            itemBuilder: (_, index) {
              final category = state.categories[index];
              return CategoryItem(
                icon: _iconFor(category.slug),
                title: category.name,
                slug: category.slug,
                isSelected: state.selectedSlug == category.slug,
              );
            },
          ),
        );
      },
    );
  }
}
