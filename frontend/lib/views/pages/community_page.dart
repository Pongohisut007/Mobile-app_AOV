import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/food/food_bloc.dart';
import 'package:flutter_application_1/bloc/food/food_event.dart';
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
    final state = categoryBloc.state;

    if (state is! CategoryLoaded &&
        state is! CategoryLoading) {
      categoryBloc.add(FetchCategoriesEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isIpad = MediaQuery.sizeOf(context).shortestSide >= 600;
    int categorySortID = 0;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: BlocBuilder<CategoryBloc, CategoryState>(
          builder: (context, state) {
            if (state is CategoryLoaded) {
              return ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                children: [
                  SizedBox(
                    height: isIpad ? 14 : 9,
                  ),
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
                      final selectedId = context.read<CategoryBloc>().state.selectedId;
                      if (query.isEmpty) {
                        // ล้างคำค้นหา = กลับไปแสดงตามหมวดที่เลือกไว้
                        foodBloc.add(FetchCommunityFoodsByCategoryEvent(selectedId));
                      } else {
                        // ค้นหาในขอบเขตของหมวดที่เลือกอยู่
                        foodBloc.add(SearchFoodEvent(query, categoryId: selectedId));
                      }
                    },
                  ),

                  const SizedBox(height: 9),

                  CategorySelector(
                    categories: state.categories,
                      onCategorySelected: (categorySID) {
                      categorySortID = categorySID ?? 0;
                    },
                  ),

                  const SizedBox(height: 9),

                  PostCard(categorySortID: categorySortID),
                ],
              );
            }

            if (state is CategoryLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state is CategoryError) {
              return Center(
                child: Text('Error: ${state.message}'),
              );
            }

            return const Center(
              child: Text('No data available.'),
            );
          },
        ),
      ),
    );
  }
}