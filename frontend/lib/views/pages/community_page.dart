import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/category/category_bloc.dart';
import 'package:flutter_application_1/bloc/category/category_event.dart';
import 'package:flutter_application_1/bloc/category/category_state.dart';
import 'package:flutter_application_1/bloc/food/food_bloc.dart';
import 'package:flutter_application_1/bloc/food/food_event.dart';
import 'package:flutter_application_1/bloc/food/food_state.dart';
import 'package:flutter_application_1/models/food.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_application_1/routes/app_routes.dart';
import 'package:flutter_application_1/views/pages/create_foodcard_page.dart';
import 'package:flutter_application_1/widgets/community/category_selector.dart';
import 'package:flutter_application_1/widgets/community/community_header.dart';
import 'package:flutter_application_1/widgets/community/community_post_list.dart';
import 'package:flutter_application_1/widgets/community/community_search.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  static const int _postsPerPage = 3;

  int _visiblePostCount = _postsPerPage;
  // กันกด + รัวจนเปิดหน้าสร้างสูตรซ้อนกัน
  bool _isOpeningCreate = false;

  void _resetVisiblePosts() {
    setState(() {
      _visiblePostCount = _postsPerPage;
    });
  }

  @override
  void initState() {
    super.initState();

    final categoryBloc = context.read<CategoryBloc>();
    final categoryState = categoryBloc.state;

    if (categoryState is! CategoryLoaded &&
        categoryState is! CategoryLoading) {
      categoryBloc.add(FetchCategoriesEvent());
    }

    context
        .read<FoodBloc>()
        .add(FetchCommunityFoodsByCategoryEvent(''));
  }

  Future<void> _createFood(CategoryLoaded categoryState) async {
    if (_isOpeningCreate) return;
    _isOpeningCreate = true;

    final bool? created;
    try {
      final creatorId = await TokenStorage().readUserId();

      if (!mounted) return;

      if (creatorId == null || creatorId.trim().isEmpty) {
        await Navigator.of(context).pushNamed(AppRoutes.login);
        return;
      }

      created = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => CreateFoodcardPage(
            categories: categoryState.categories,
            isFromCommunity: true,
          ),
        ),
      );
    } finally {
      _isOpeningCreate = false;
    }

    if (!mounted || created != true) return;

    _resetVisiblePosts();

    context.read<FoodBloc>().add(
      FetchCommunityFoodsByCategoryEvent(
        context.read<CategoryBloc>().state.selectedId,
      ),
    );
  }

  void _searchFood(String query) {
    final foodBloc = context.read<FoodBloc>();
    final selectedId = context.read<CategoryBloc>().state.selectedId;

    _resetVisiblePosts();

    if (query.isEmpty) {
      foodBloc.add(
        FetchCommunityFoodsByCategoryEvent(selectedId),
      );
    } else {
      foodBloc.add(
        SearchFoodEvent(
          query,
          categoryId: selectedId,
          type: 'community',
        ),
      );
    }
  }

  // ดึงลงเพื่อโหลดโพสต์ใหม่ ถ้ากำลังค้นหาอยู่ก็ค้นหาคำเดิมซ้ำ
  Future<void> _refresh() async {
    final foodBloc = context.read<FoodBloc>();
    final selectedId = context.read<CategoryBloc>().state.selectedId;
    final currentState = foodBloc.state;
    final query = currentState is FoodLoaded ? currentState.query : null;

    _resetVisiblePosts();
    final done = foodBloc.stream.firstWhere(
      (state) => state is FoodLoaded || state is FoodError,
    );
    foodBloc.add(
      query == null
          ? FetchCommunityFoodsByCategoryEvent(selectedId)
          : SearchFoodEvent(query, categoryId: selectedId, type: 'community'),
    );
    await done;
  }

  void _selectCategory(String? uuid) {
    _resetVisiblePosts();

    context.read<FoodBloc>().add(
      FetchCommunityFoodsByCategoryEvent(uuid ?? ''),
    );
  }

  List<Food> _sortFoods(List<Food> foods) {
    final sortedFoods = foods.toList();

    sortedFoods.sort((left, right) {
      final leftPublishedAt = left.publishedAt;
      final rightPublishedAt = right.publishedAt;

      if (leftPublishedAt == null) {
        return rightPublishedAt == null ? 0 : 1;
      }

      if (rightPublishedAt == null) return -1;

      return rightPublishedAt.compareTo(leftPublishedAt);
    });

    return sortedFoods;
  }

  @override
  Widget build(BuildContext context) {
    final bool isIpad =
        MediaQuery.sizeOf(context).shortestSide >= 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: BlocBuilder<CategoryBloc, CategoryState>(
          builder: (context, categoryState) {
            if (categoryState is CategoryLoaded) {
              return BlocBuilder<FoodBloc, FoodState>(
                builder: (context, foodState) {
                  final foods = foodState is FoodLoaded
                      ? _sortFoods(foodState.foods)
                      : <Food>[];

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      // ระยะห่างเดียวกับหน้า Home/Profile
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                      children: [
                        CommunityHeader(
                          isIpad: isIpad,
                          onAddPressed: () {
                            _createFood(categoryState);
                          },
                        ),

                        const SizedBox(height: 20),

                        CommunitySearch(
                          onSearch: _searchFood,
                        ),

                        const SizedBox(height: 20),

                        CategorySelector(
                          categories: categoryState.categories,
                          onCategorySelected: _selectCategory,
                        ),

                        const SizedBox(height: 20),

                        CommunityPostList(
                          foodState: foodState,
                          foods: foods,
                          visiblePostCount: _visiblePostCount,
                          postsPerPage: _postsPerPage,
                          onShowMore: () {
                            setState(() {
                              _visiblePostCount += _postsPerPage;
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            }

            if (categoryState is CategoryLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (categoryState is CategoryError) {
              return Center(
                child: Text(
                  'Error: ${categoryState.message}',
                ),
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
