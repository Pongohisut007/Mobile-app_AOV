import 'dart:async';

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

  // ช่องค้นหาในหน้ากับช่องค้นหาบน app bar ใช้ข้อความเดียวกัน
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _listKey = GlobalKey();
  final _searchKey = GlobalKey();
  final _categoryKey = GlobalKey();
  Timer? _searchDebounce;
  String _lastQuery = '';

  // เลื่อนผ่านแถบหมวดหมู่ไปแล้ว = โชว์ปุ่มค้นหาบน app bar
  bool _isPastFilter = false;
  bool _isSearchExpanded = false;
  // กำลังเลื่อนกลับขึ้นบนหลังค้นหาจาก app bar ไม่ให้ปุ่มค้นหาโผล่วูบระหว่างทาง
  bool _isScrollingToTop = false;

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

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// ขอบล่างของ widget เทียบกับขอบบนของรายการ (ติดลบ/ศูนย์ = เลื่อนพ้นไปแล้ว)
  double? _bottomBelowListTop(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    final listBox = _listKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || listBox == null) return null;
    final bottom = box.localToGlobal(Offset(0, box.size.height)).dy;
    return bottom - listBox.localToGlobal(Offset.zero).dy;
  }

  void _onScroll() {
    if (_isScrollingToTop) return;
    final filterBottom = _bottomBelowListTop(_categoryKey);
    final searchBottom = _bottomBelowListTop(_searchKey);

    // ListView ทิ้ง widget ที่เลื่อนพ้นจอไปไกล ๆ หา key ไม่เจอ = เลื่อนพ้นไปแล้ว
    final scrolledDown =
        _scrollController.hasClients && _scrollController.offset > 0;
    final isPastFilter = filterBottom == null
        ? scrolledDown
        : filterBottom <= 0;
    // เลื่อนกลับขึ้นมาจนเห็นช่องค้นหาในหน้าแล้ว ก็หดช่องบน app bar กลับ
    final searchVisible = searchBottom != null && searchBottom > 0;
    final collapse = _isSearchExpanded && searchVisible;

    if (isPastFilter == _isPastFilter && !collapse) return;
    setState(() {
      _isPastFilter = isPastFilter;
      if (collapse) _isSearchExpanded = false;
    });
  }

  void _openSearch() => setState(() => _isSearchExpanded = true);

  // หดกลับอย่างเดียว คำที่ค้นหาและผลค้นหายังอยู่
  void _closeSearch() {
    FocusScope.of(context).unfocus();
    setState(() => _isSearchExpanded = false);
  }

  void _onAppBarSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 400),
      () => _searchFood(value),
    );
  }

  // กดค้นหาจาก app bar แล้ว ให้เหมือนค้นหาจากช่องหลัก:
  // หดช่องบน app bar (คำว่า Community กลับมา) แล้วเลื่อนกลับขึ้นไปที่ช่องค้นหาหลัก
  Future<void> _onAppBarSearchSubmitted(String value) async {
    _searchDebounce?.cancel();
    _searchFood(value);

    FocusScope.of(context).unfocus();
    setState(() {
      _isSearchExpanded = false;
      _isPastFilter = false;
    });

    if (!_scrollController.hasClients) return;
    _isScrollingToTop = true;
    try {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } finally {
      _isScrollingToTop = false;
    }
    if (mounted) _onScroll();
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

  void _searchFood(String rawQuery) {
    final query = rawQuery.trim();
    // สองช่องค้นหาส่งเข้ามาที่นี่ทั้งคู่ กันยิงคำเดิมซ้ำ
    if (query == _lastQuery) return;
    _lastQuery = query;

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
    // เปลี่ยนหมวดจะโหลดโพสต์ทั้งหมดของหมวดนั้น พิมพ์คำเดิมค้นหาใหม่ได้
    _lastQuery = '';

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
      appBar: CommunityHeader(
        isIpad: isIpad,
        // หน้าสร้างสูตรต้องใช้รายการหมวดหมู่ ยังโหลดไม่เสร็จก็ยังกดไม่ได้
        onAddPressed: () {
          final categoryState = context.read<CategoryBloc>().state;
          if (categoryState is CategoryLoaded) _createFood(categoryState);
        },
        searchController: _searchController,
        showSearchButton: _isPastFilter,
        isSearchExpanded: _isSearchExpanded,
        onSearchPressed: _openSearch,
        onSearchClosed: _closeSearch,
        onSearchChanged: _onAppBarSearchChanged,
        onSearchSubmitted: _onAppBarSearchSubmitted,
      ),
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
                      key: _listKey,
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      // ระยะห่างเดียวกับหน้า Home/Profile
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      children: [
                        CommunitySearch(
                          key: _searchKey,
                          controller: _searchController,
                          onSearch: _searchFood,
                        ),

                        const SizedBox(height: 20),

                        CategorySelector(
                          key: _categoryKey,
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
