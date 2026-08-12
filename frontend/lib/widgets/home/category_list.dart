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
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // < 600 มือถือ, >= 600 iPad
        final isMedium = width >= 600;

        final listHeight = isMedium ? 110.0 : 90.0;
        final itemWidth = isMedium ? 100.0 : 80.0;
        final iconSize = isMedium ? 38.0 : 30.0;
        final fontSize = isMedium ? 14.0 : 12.0;
        final verticalPadding = isMedium ? 16.0 : 12.0;

        return BlocConsumer<CategoryBloc, CategoryState>(
          listenWhen: (previous, current) =>
              previous.selectedId != current.selectedId,
          listener: (context, state) {
            context.read<FoodBloc>().add(
              FetchFoodByCategoryEvent(state.selectedId),
            );
          },
          builder: (context, state) {
            if (state is CategoryLoading) {
              return SizedBox(
                height: listHeight,
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            if (state is CategoryError) {
              return SizedBox(
                height: listHeight,
                child: Center(child: Text(state.message)),
              );
            }

            if (state is! CategoryLoaded) {
              return SizedBox(height: listHeight);
            }

            return SizedBox(
              height: listHeight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: state.categories.length,
                itemBuilder: (_, index) {
                  final category = state.categories[index];
                  return CategoryItem(
                    icon: _iconFor(category.slug),
                    title: category.name,
                    categoryId: category.id,
                    isSelected: state.selectedId == category.id,
                    itemWidth: itemWidth,
                    iconSize: iconSize,
                    fontSize: fontSize,
                    verticalPadding: verticalPadding,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}