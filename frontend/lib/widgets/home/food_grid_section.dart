import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/category/category_bloc.dart';
import 'package:flutter_application_1/bloc/category/category_state.dart';
import 'package:flutter_application_1/bloc/food/food_bloc.dart';
import 'package:flutter_application_1/bloc/food/food_event.dart';
import 'package:flutter_application_1/bloc/food/food_state.dart';
import 'package:flutter_application_1/bloc/purchased_recipes/purchased_recipes_bloc.dart';
import 'package:flutter_application_1/bloc/purchased_recipes/purchased_recipes_state.dart';
import 'package:flutter_application_1/models/food.dart';
import 'package:flutter_application_1/views/pages/food_detail_page.dart';
import 'package:flutter_application_1/widgets/home/food_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// grid การ์ดสูตรจาก FoodBloc ใช้ร่วมกันระหว่างหน้า home กับหน้า See More
/// maxItems = แสดงไม่เกินจำนวนนี้ (null = ทั้งหมดที่โหลดมาแล้ว)
/// หน้าที่ใช้เป็นคนสั่งโหลดหน้าถัดไปเอง ดู [needsMore]
class FoodGridSection extends StatelessWidget {
  const FoodGridSection({this.maxItems, super.key});

  final int? maxItems;

  // ซ่อนสูตรที่ซื้อแล้ว ไปเปิดได้จากหน้า "สูตรที่ซื้อแล้ว" แทน
  static List<Food> visibleFoods(
    FoodLoaded state,
    PurchasedRecipesState purchased, {
    int? maxItems,
  }) {
    final foods = state.foods.where(
      (food) => !purchased.isPurchased(food.idfoods),
    );
    return (maxItems == null ? foods : foods.take(maxItems)).toList(
      growable: false,
    );
  }

  /// ยังแสดงไม่ครบ maxItems (เช่น ซ่อนสูตรที่ซื้อแล้วไปหลายอัน) และ backend ยังมีหน้าถัดไป
  /// โหลดพลาดไม่นับ ให้ผู้ใช้กดลองใหม่เอง ไม่วนยิงซ้ำ
  static bool needsMore(
    FoodState state,
    PurchasedRecipesState purchased,
    int maxItems,
  ) {
    if (state is! FoodLoaded || !state.hasMore) return false;
    if (state.loadMoreError != null) return false;
    return visibleFoods(state, purchased, maxItems: maxItems).length <
        maxItems;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FoodBloc, FoodState>(
      builder: (context, state) {
        if (state is FoodInitial) {
          return const Center(child: Text("Initial Loading..."));
        }
        if (state is FoodLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is FoodError) {
          return Center(child: Text(state.message));
        }
        if (state is! FoodLoaded) return const SizedBox.shrink();

        final purchased = context.watch<PurchasedRecipesBloc>().state;
        final foods = visibleFoods(state, purchased, maxItems: maxItems);
        final limit = maxItems;
        // ครบตามจำนวนที่จะแสดงแล้ว ไม่ต้องมีตัวหมุน/ปุ่มลองใหม่ท้ายรายการ
        final isFull = limit != null && foods.length >= limit;
        final footer = isFull
            ? const SizedBox(height: 8)
            : _LoadMoreFooter(
                state: state,
                onRetry: () =>
                    context.read<FoodBloc>().add(FoodLoadMoreRequested()),
              );

        // หน้านี้ถูกซ่อนหมดแต่ยังมีหน้าถัดไป = รอโหลดหน้าถัดไปก่อน
        if (foods.isEmpty && state.hasMore) return footer;

        if (foods.isEmpty) {
          final query = state.query;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                query == null
                    ? 'ยังไม่มีเมนูในหมวดนี้'
                    : 'ไม่พบเมนูที่ชื่อ "$query"',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        // กรองหมวดอยู่ = การ์ดแสดงชื่อหมวดนั้น (สูตรมีได้หลายหมวด)
        // ไม่กรอง = ปล่อยให้การ์ดใช้หมวดแรกของสูตรเอง
        final categoryState = context.read<CategoryBloc>().state;
        final selectedCategoryName = categoryState is CategoryLoaded
            ? categoryState.categories
                  .where((category) => category.id == categoryState.selectedId)
                  .map((category) => category.name)
                  .firstOrNull
            : null;

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            // < 600 มือถือ = 2 คอลัมน์, >= 600 iPad = 3 คอลัมน์
            final crossAxisCount = width >= 900 ? 4 : (width >= 600 ? 3 : 2);

            final grid = GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: foods.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: .68,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemBuilder: (_, index) {
                final food = foods[index];
                return FoodCard(
                  food: food,
                  categoryLabel: selectedCategoryName,
                  onTap: () async {
                    final foodBloc = context.read<FoodBloc>();
                    // หน้ารายละเอียดคืน true = ลบสูตรไปแล้ว
                    final deleted = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute<bool>(
                        builder: (_) => FoodDetailPage(foodsId: food.idfoods),
                      ),
                    );
                    if (deleted == true) {
                      foodBloc.add(FoodRemoved(food.idfoods));
                    }
                  },
                );
              },
            );

            return Column(children: [grid, footer]);
          },
        );
      },
    );
  }
}

/// ท้ายรายการ: ตัวหมุนตอนโหลดหน้าถัดไป หรือปุ่มลองใหม่ถ้าโหลดพลาด
class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({required this.state, required this.onRetry});

  final FoodLoaded state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('โหลดเมนูเพิ่มไม่สำเร็จ ลองอีกครั้ง'),
          ),
        ),
      );
    }
    if (state.hasMore || state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return const SizedBox(height: 8);
  }
}
