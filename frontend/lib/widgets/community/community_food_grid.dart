import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/food.dart';
import 'package:flutter_application_1/routes/app_routes.dart';
import 'package:flutter_application_1/widgets/home/food_card.dart';

class CommunityFoodGrid extends StatelessWidget {
  const CommunityFoodGrid({
    super.key,
    required this.foods,
  });

  final List<Food> foods;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(15),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final food = foods[index];

            return FoodCard(
              food: food,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.foodDetail,
                  arguments: food.idfoods,
                );
              },
            );
          },
          childCount: foods.length,
        ),
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: .68,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
        ),
      ),
    );
  }
}