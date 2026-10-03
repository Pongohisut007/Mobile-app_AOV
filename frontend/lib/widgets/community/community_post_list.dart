import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/food/food_state.dart';
import 'package:flutter_application_1/models/food.dart';
import 'package:flutter_application_1/widgets/community/post_card.dart';

class CommunityPostList extends StatelessWidget {
  const CommunityPostList({
    super.key,
    required this.foodState,
    required this.foods,
    required this.visiblePostCount,
    required this.postsPerPage,
    required this.onShowMore,
  });

  final FoodState foodState;
  final List<Food> foods;
  final int visiblePostCount;
  final int postsPerPage;
  final VoidCallback onShowMore;

  @override
  Widget build(BuildContext context) {
    if (foodState is FoodLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 32),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (foodState is FoodError) {
      return Padding(
        padding: const EdgeInsets.only(top: 32),
        child: Center(
          child: Text(
            'Error: ${(foodState as FoodError).message}',
          ),
        ),
      );
    }

    if (foodState is! FoodLoaded) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        ...foods
            .take(visiblePostCount)
            .map(
              (food) => PostCard(food: food),
            ),

        if (foods.length > visiblePostCount)
          Padding(
            padding: const EdgeInsets.only(
              top: 8,
              bottom: 16,
            ),
            child: Center(
              child: TextButton(
                onPressed: onShowMore,
                child: const Text('แสดงเพิ่ม'),
              ),
            ),
          ),
      ],
    );
  }
}