import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/food/food_bloc.dart';
import 'package:flutter_application_1/bloc/food/food_event.dart';
import 'package:flutter_application_1/bloc/food/food_state.dart';
import 'package:flutter_application_1/widgets/community/category_selector.dart';
import 'package:flutter_application_1/widgets/community/post_card.dart';
import 'package:flutter_application_1/widgets/home/search_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/bloc/category/category_bloc.dart';
import 'package:flutter_application_1/bloc/category/category_event.dart';
import 'package:flutter_application_1/bloc/category/category_state.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  @override
  void initState() {
    super.initState();

    final categoryBloc = context.read<CategoryBloc>();
    final categoryState = categoryBloc.state;

    if (categoryState is! CategoryLoaded &&
        categoryState is! CategoryLoading) {
      categoryBloc.add(FetchCategoriesEvent());
    }

    // โหลด community foods ครั้งแรก (ทุกหมวด)
    final foodBloc = context.read<FoodBloc>();
    final foodState = foodBloc.state;
    if (foodState is! FoodLoaded && foodState is! FoodLoading) {
      foodBloc.add(FetchCommunityFoodsByCategoryEvent(''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isIpad = MediaQuery.sizeOf(context).shortestSide >= 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: BlocBuilder<CategoryBloc, CategoryState>(
          builder: (context, categoryState) {
            if (categoryState is CategoryLoaded) {
              return BlocBuilder<FoodBloc, FoodState>(
                builder: (context, foodState) {
                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      SizedBox(height: isIpad ? 14 : 9),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Community',
                          style: TextStyle(
                            fontSize: isIpad ? 35 : 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 9),

                      SearchBarWidget(
                        onSearch: (query) {
                          final foodBloc = context.read<FoodBloc>();
                          final selectedId =
                              context.read<CategoryBloc>().state.selectedId;
                          if (query.isEmpty) {
                            foodBloc.add(
                                FetchCommunityFoodsByCategoryEvent(selectedId));
                          } else {
                            foodBloc.add(
                                SearchFoodEvent(query, categoryId: selectedId));
                          }
                        },
                      ),

                      const SizedBox(height: 9),

                      CategorySelector(
                        categories: categoryState.categories,
                        onCategorySelected: (uuid) {
                          context.read<FoodBloc>().add(
                                FetchCommunityFoodsByCategoryEvent(uuid ?? ''),
                              );
                        },
                      ),

                      const SizedBox(height: 9),

                      // แสดง PostCard ตามจำนวน foods ที่ได้จาก FetchCommunityFoodsByCategoryEvent
                      if (foodState is FoodLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 32),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (foodState is FoodLoaded)
                        ...foodState.foods
                            .map((food) => PostCard(food: food))
                      else if (foodState is FoodError)
                        Padding(
                          padding: const EdgeInsets.only(top: 32),
                          child: Center(
                              child: Text('Error: ${foodState.message}')),
                        ),
                    ],
                  );
                },
              );
            }

            if (categoryState is CategoryLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (categoryState is CategoryError) {
              return Center(
                child: Text('Error: ${categoryState.message}'),
              );
            }

            return const Center(child: Text('No data available.'));
          },
        ),
      ),
    );
  }
}