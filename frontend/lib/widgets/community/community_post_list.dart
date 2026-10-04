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
    required this.onShowMore,
  });

  final FoodState foodState;
  final List<Food> foods;

  /// โหลดหน้าถัดไปจาก backend
  final VoidCallback onShowMore;

  @override
  Widget build(BuildContext context) {
    if (foodState is FoodLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (foodState is FoodError) {
      return Padding(
        padding: const EdgeInsets.only(top: 32),
        child: Center(
          child: Text('Error: ${(foodState as FoodError).message}'),
        ),
      );
    }

    if (foodState is! FoodLoaded) {
      return const SizedBox.shrink();
    }

    final loaded = foodState as FoodLoaded;

    if (foods.isEmpty) {
      final query = loaded.query;
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
        ...foods.map((food) => PostCard(food: food)),

        if (loaded.hasMore || loaded.loadMoreError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Center(
              child: OutlinedButton(
                onPressed: loaded.isLoadingMore ? null : onShowMore,
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
                child: loaded.isLoadingMore
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ProfileColors.ink,
                        ),
                      )
                    : Text(
                        loaded.loadMoreError != null
                            ? 'โหลดไม่สำเร็จ ลองอีกครั้ง'
                            : 'แสดงเพิ่ม',
                      ),
              ),
            ),
          ),
      ],
    );
  }
}
