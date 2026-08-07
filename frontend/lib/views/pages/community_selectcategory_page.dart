import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/category/category_bloc.dart';
import 'package:flutter_application_1/bloc/category/category_state.dart';
import 'package:flutter_application_1/bloc/food/food_bloc.dart';
import 'package:flutter_application_1/bloc/food/food_event.dart';
import 'package:flutter_application_1/bloc/food/food_state.dart';
import 'package:flutter_application_1/views/pages/food_detail_pageg.dart';
import 'package:flutter_application_1/widgets/community/category_header_delegate.dart';
import 'package:flutter_application_1/widgets/home/food_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CommunitySelectCategoryPage extends StatefulWidget {
  const CommunitySelectCategoryPage({
    super.key,
    required this.categoryUUID,
    required this.categoryImageUrl,
  });

  final String categoryUUID;
  final String categoryImageUrl;

  @override
  State<CommunitySelectCategoryPage> createState() =>
      _CommunitySelectCategoryPageState();
}

class _CommunitySelectCategoryPageState
    extends State<CommunitySelectCategoryPage> {
  
  String? selectedCategoryId;
  late String categoryImageUrl;

  @override
  void initState() {
    super.initState();

    categoryImageUrl = widget.categoryImageUrl;
    selectedCategoryId = widget.categoryUUID;

    final foodBloc = context.read<FoodBloc>();

    if (foodBloc.state is! FoodLoaded &&
        foodBloc.state is! FoodLoading) {
      foodBloc.add(
        // FetchFoodByCategoryEvent(widget.categoryUUID),
        FetchFoodEvent(), //test
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<FoodBloc, FoodState>(
        builder: (context, state) {

          if (state is FoodLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is FoodLoaded) {
            final foods = state.foods;

            return CustomScrollView(
              slivers: [
                // AppBar + รูป Header
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 250,

                  backgroundColor: Colors.transparent,

                  flexibleSpace: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            categoryImageUrl,
                            fit: BoxFit.cover,
                            alignment: Alignment.bottomCenter,
                          ),

                          Container(
                            color: Colors.black.withOpacity(0.2),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                SliverPersistentHeader(
                  pinned: true,
                  delegate: CategoryHeaderDelegate(
                    child: BlocBuilder<CategoryBloc, CategoryState>(
                      builder: (context, state) {

                        if (state is CategoryLoaded) {
                          final categories = state.categories;

                          return Container(
                            height: 80,
                            color: Colors.white,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: categories.length,
                              itemBuilder: (context, index) {

                                final category = categories[index];
                                final isSelected = selectedCategoryId == category.id;

                                return GestureDetector(
                                  onTap: () {
                                    if (selectedCategoryId == category.id) {
                                      return;
                                    }
                                    
                                    setState(() {
                                      categoryImageUrl = category.imageUrl ?? '';
                                      selectedCategoryId = category.id;
                                    });
                                    
                                    context.read<FoodBloc>().add(
                                      FetchFoodByCategoryEvent(
                                        category.id,
                                      ),
                                    );
                                  },
                                  child: Card(
                                    elevation: isSelected ? 8 : 3,
                                    color: isSelected
                                        ? Colors.blue.shade100
                                        : Colors.white,
                                    margin: const EdgeInsets.all(8),

                                    child: SizedBox(
                                      width: 100,
                                      child: Center(
                                        child: Text(
                                          category.name,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),

                // Food Grid
                SliverPadding(
                  padding: const EdgeInsets.all(15),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {

                        final food = foods[index];

                        return FoodCard(
                          food: food,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FoodDetailPage(
                                  foodsId: food.idfoods,
                                ),
                              ),
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
                ),
              ],
            );
          }


          if (state is FoodError) {
            return Center(
              child: Text(
                'Error: ${state.message}',
              ),
            );
          }


          return const Center(
            child: Text('No data available.'),
          );
        },
      ),
    );
  }
}