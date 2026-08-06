import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/bloc/food_category/food_category_bloc.dart';
import 'package:flutter_application_1/bloc/food_category/food_category_event.dart';
import 'package:flutter_application_1/bloc/food_category/food_category_state.dart';
import 'package:flutter_application_1/widgets/community/category_card.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  @override
  void initState() {
    super.initState();

    // โหลด Category เมื่อเปิดหน้า
    context.read<FoodCategoryBloc>().add(FetchFoodCategoryEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: BlocBuilder<FoodCategoryBloc, FoodCategoryState>(
            builder: (context, state) {
              if (state is FoodCategoryInitial ||
                  state is FoodCategoryLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (state is FoodCategoryLoaded) {
                if (state.categories.isEmpty) {
                  return const Center(
                    child: Text(
                      "ไม่มีหมวดหมู่อาหาร",
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return GridView.builder(
                  itemCount: state.categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,          // แสดง 1 การ์ดต่อแถว
                    childAspectRatio: 2.8,      // กว้าง : สูง = 2.8 : 1
                    mainAxisSpacing: 16,
                  ),
                  itemBuilder: (context, index) {
                    final category = state.categories[index];

                    return CategoryCard(
                      category: category,
                      onTap: () {
                        debugPrint('Category: ${category.name}');
                      },
                    );
                  },
                );
              }

              if (state is FoodCategoryError) {
                return Center(
                  child: Text(
                    state.message,
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}