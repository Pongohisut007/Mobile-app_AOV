import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/food/food_state.dart';
import 'package:flutter_application_1/models/food.dart';
import 'package:flutter_application_1/widgets/community/post_card.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';

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

    if (foods.isEmpty) {
      final query = (foodState as FoodLoaded).query;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            query == null
                ? 'ยังไม่มีโพสต์ในหมวดนี้'
                : 'ไม่พบโพสต์ที่ชื่อ "$query"',
            style: const TextStyle(color: ProfileColors.muted),
          ),
        ),
      );
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
            padding: const EdgeInsets.only(bottom: 16),
            child: Center(
              child: OutlinedButton(
                onPressed: onShowMore,
                style: OutlinedButton.styleFrom(
                  foregroundColor: ProfileColors.ink,
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
                child: const Text('แสดงเพิ่ม'),
              ),
            ),
          ),
      ],
    );
  }
}