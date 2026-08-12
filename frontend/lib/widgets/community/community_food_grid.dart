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
      padding: EdgeInsets.all(
        MediaQuery.sizeOf(context).shortestSide >= 600
            ? 24
            : 15,
      ),
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
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          // Phone = 2 columns
          // iPad = 3 columns
          crossAxisCount:
              MediaQuery.sizeOf(context).shortestSide >= 600
                  ? 3
                  : 2,

          // iPad card จะกว้างขึ้นเล็กน้อย
          childAspectRatio:
              MediaQuery.sizeOf(context).shortestSide >= 600
                  ? 0.72
                  : 0.68,

          crossAxisSpacing:
              MediaQuery.sizeOf(context).shortestSide >= 600
                  ? 20
                  : 15,

          mainAxisSpacing:
              MediaQuery.sizeOf(context).shortestSide >= 600
                  ? 20
                  : 15,
        ),
      ),
    );
  }
}