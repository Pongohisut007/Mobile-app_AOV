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
  // กันกด + รัวจนเปิดหน้าสร้างสูตรซ้อนกัน
  bool _isOpeningCreate = false;

  // ที่เก็บคำค้นหามีที่เดียวคือช่องหลักในหน้า หน่วงเวลาด้วยตัวหน่วงตัวเดียวที่นี่
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  // ช่องบน app bar มีไว้แค่รับตัวอักษรแรก แล้วส่งต่อให้ช่องหลัก (ตัวมันเองว่างเสมอ)
  final _appBarSearchController = TextEditingController();
  final _scrollController = ScrollController();
  final _listKey = GlobalKey();
  final _searchKey = GlobalKey();
  final _categoryKey = GlobalKey();
  Timer? _searchDebounce;
  String _lastQuery = '';

  // หมวดที่เลือกในหน้านี้ เก็บเอง ไม่ใช้ของ CategoryBloc เพราะแชร์กับหน้า Home
  // (ค่าว่าง = ทุกหมวด)
  String _selectedCategoryId = '';

  // เลื่อนผ่านแถบหมวดหมู่ไปแล้ว = โชว์ปุ่มค้นหาบน app bar
  bool _isPastFilter = false;
  bool _isSearchExpanded = false;
  // กำลังย้ายจากช่อง app bar ไปช่องหลัก ไม่ให้ตัวฟังการเลื่อนมาหดแถบก่อนเคอร์เซอร์ย้ายเสร็จ
  bool _isHandingOff = false;

  @override
  void initState() {
    super.initState();

    final categoryBloc = context.read<CategoryBloc>();
    final categoryState = categoryBloc.state;

    if (categoryState is! CategoryLoaded && categoryState is! CategoryLoading) {
      categoryBloc.add(FetchCategoriesEvent());
    }

    context.read<FoodBloc>().add(FetchCommunityFoodsByCategoryEvent(''));

    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    _appBarSearchController.dispose();
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
    if (_isHandingOff) return;
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

  // หดกลับอย่างเดียว คำที่ค้นหาในช่องหลักและผลค้นหายังอยู่
  void _closeSearch() {
    FocusScope.of(context).unfocus();
    _appBarSearchController.clear();
    setState(() => _isSearchExpanded = false);
  }

  // พิมพ์ตัวแรกในช่อง app bar: ย้ายข้อความไปช่องหลัก ล้างช่อง app bar
  // กระโดดขึ้นบนสุด ย้ายเคอร์เซอร์ไปช่องหลัก แล้ว app bar กลับเป็นแบบตอนแรก
  void _onAppBarSearchChanged(String value) {
    if (value.isEmpty || _isHandingOff) return;

    _appBarSearchController.clear();
    // ช่อง app bar เปิดมาว่างเสมอ = เริ่มคำค้นหาใหม่ แทนที่คำเดิมในช่องหลัก
    _searchController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );

    _isHandingOff = true;
    if (_scrollController.hasClients) _scrollController.jumpTo(0);

    // รอเฟรมถัดไปให้ช่องหลักถูกสร้างบนจอก่อน (ListView อาจทิ้งไปแล้วตอนเลื่อนลงลึก)
    // ย้ายเคอร์เซอร์ก่อนค่อยหดแถบ คีย์บอร์ดจะได้ไม่ปิดแล้วเปิดใหม่
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _searchFocus.requestFocus();
      setState(() {
        _isSearchExpanded = false;
        _isPastFilter = false;
      });
      _isHandingOff = false;
    });
  }

  // ช่องหลักเปลี่ยน: หยุดพิมพ์ 400ms แล้วค้นหาด้วยข้อความล่าสุดในช่อง
  void _onSearchTextChanged() {
    if (_searchController.text.trim() == _lastQuery) {
      _searchDebounce?.cancel();
      return;
    }
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 400),
      () => _searchFood(_searchController.text),
    );
  }

  // ช่อง app bar ว่างเสมอ (พิมพ์ตัวแรกก็ย้ายไปช่องหลักแล้ว) กด enter ตอนว่าง = ปิดช่อง
  void _onAppBarSearchSubmitted(String value) {
    if (value.isNotEmpty) {
      _onAppBarSearchChanged(value);
      return;
    }
    _closeSearch();
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

    context.read<FoodBloc>().add(
      FetchCommunityFoodsByCategoryEvent(_selectedCategoryId),
    );
  }

  void _searchFood(String rawQuery) {
    // ค้นหาทันที (enter / กดล้าง) แล้ว ตัวหน่วงที่ค้างอยู่ต้องไม่ยิงซ้ำตามมา
    _searchDebounce?.cancel();
    final query = rawQuery.trim();
    // สองช่องค้นหาส่งเข้ามาที่นี่ทั้งคู่ กันยิงคำเดิมซ้ำ
    if (query == _lastQuery) return;
    _lastQuery = query;

    final foodBloc = context.read<FoodBloc>();
    final selectedId = _selectedCategoryId;

    if (query.isEmpty) {
      foodBloc.add(FetchCommunityFoodsByCategoryEvent(selectedId));
    } else {
      foodBloc.add(
        SearchFoodEvent(query, categoryId: selectedId, type: 'community'),
      );
    }
  }

  // ดึงลงเพื่อโหลดโพสต์ใหม่ ถ้ากำลังค้นหาอยู่ก็ค้นหาคำเดิมซ้ำ
  Future<void> _refresh() async {
    final foodBloc = context.read<FoodBloc>();
    final selectedId = _selectedCategoryId;
    final currentState = foodBloc.state;
    final query = currentState is FoodLoaded ? currentState.query : null;

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
    _selectedCategoryId = uuid ?? '';
    // มีคำค้นหาอยู่ = ค้นหาคำเดิมในหมวดใหม่ ไม่มี = โหลดโพสต์ทั้งหมดของหมวด
    _searchDebounce?.cancel();
    final query = _searchController.text.trim();
    _lastQuery = query;

    context.read<FoodBloc>().add(
      query.isEmpty
          ? FetchCommunityFoodsByCategoryEvent(_selectedCategoryId)
          : SearchFoodEvent(
              query,
              categoryId: _selectedCategoryId,
              type: 'community',
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isIpad = MediaQuery.sizeOf(context).shortestSide >= 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: CommunityHeader(
        isIpad: isIpad,
        // หน้าสร้างสูตรต้องใช้รายการหมวดหมู่ ยังโหลดไม่เสร็จก็ยังกดไม่ได้
        onAddPressed: () {
          final categoryState = context.read<CategoryBloc>().state;
          if (categoryState is CategoryLoaded) _createFood(categoryState);
        },
        searchController: _appBarSearchController,
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
                  // backend เรียงจากเผยแพร่ล่าสุดมาให้แล้ว
                  final foods = foodState is FoodLoaded
                      ? foodState.foods
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
                          focusNode: _searchFocus,
                          onSearch: _searchFood,
                        ),

                        const SizedBox(height: 20),

                        CategorySelector(
                          key: _categoryKey,
                          categories: categoryState.categories,
                          onCategorySelected: _selectCategory,
                        ),

                        // แถบหมวดเผื่อที่ให้เงาไว้ข้างล่างแล้ว 8
                        const SizedBox(height: 12),

                        CommunityPostList(
                          foodState: foodState,
                          foods: foods,
                          // ขอหน้าถัดไปจาก backend
                          onShowMore: () => context.read<FoodBloc>().add(
                            FoodLoadMoreRequested(),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }

            if (categoryState is CategoryLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (categoryState is CategoryError) {
              return Center(child: Text('Error: ${categoryState.message}'));
            }

            return const Center(child: Text('No data available.'));
          },
        ),
      ),
    );
  }
}
