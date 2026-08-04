import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/bloc/category/category_bloc.dart';
import 'package:flutter_application_1/bloc/category/category_state.dart';
import 'package:flutter_application_1/bloc/food/food_bloc.dart';
import 'package:flutter_application_1/bloc/food/food_event.dart';

import 'category_item.dart';

class CategoryList extends StatelessWidget {
  const CategoryList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<CategoryBloc, CategoryState>(
      listenWhen: (previous, current) =>
          previous.selectedCategory != current.selectedCategory,
      listener: (context, state) {
        context.read<FoodBloc>().add(
          FetchFoodByCategoryEvent(state.selectedCategory),
        );
      },
      child: SizedBox(
        height: 90,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: const [
            CategoryItem(icon: Icons.lunch_dining, title: "Noodle"),

            CategoryItem(icon: Icons.set_meal, title: "Chicken"),

            CategoryItem(icon: Icons.fastfood, title: "Fries"),

            CategoryItem(icon: Icons.local_drink, title: "soup"),

            CategoryItem(icon: Icons.icecream, title: "Dessert"),
          ],
        ),
      ),
    );
  }
}