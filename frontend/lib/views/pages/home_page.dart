import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/banner/banner_bloc.dart';
import 'package:flutter_application_1/bloc/banner/banner_event.dart';
import 'package:flutter_application_1/bloc/category/category_bloc.dart';
import 'package:flutter_application_1/bloc/food/food_bloc.dart';
import 'package:flutter_application_1/bloc/food/food_event.dart';
import 'package:flutter_application_1/bloc/food/food_state.dart';
import 'package:flutter_application_1/bloc/purchased_recipes/purchased_recipes_bloc.dart';
import 'package:flutter_application_1/bloc/purchased_recipes/purchased_recipes_state.dart';
import 'package:flutter_application_1/views/pages/recommended_page.dart';
import 'package:flutter_application_1/widgets/home/category_list.dart';
import 'package:flutter_application_1/widgets/home/food_grid_section.dart';
import 'package:flutter_application_1/widgets/home/home_banner.dart';
import 'package:flutter_application_1/widgets/home/search_bar.dart';
import 'package:flutter_application_1/widgets/home/section_title.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Recommended แสดงสูตรคะแนนรีวิวสูงสุดไม่เกินจำนวนนี้ ที่เหลือดูได้ในหน้า See More
  static const _maxRecommended = 6;

  // คำค้นหาปัจจุบัน ใช้ค้นหาซ้ำตอนเปลี่ยนหมวดและตอนดึงรีเฟรช
  String _query = '';

  // ซ่อนสูตรที่ซื้อแล้วจนเหลือไม่ถึง 6 อัน = โหลดหน้าถัดไปมาเติมให้ครบ
  // bloc กันซ้ำเองถ้ากำลังโหลดอยู่
  void _fillRecommended() {
    if (!mounted) return;
    final foodBloc = context.read<FoodBloc>();
    final purchased = context.read<PurchasedRecipesBloc>().state;
    if (FoodGridSection.needsMore(foodBloc.state, purchased, _maxRecommended)) {
      foodBloc.add(FoodLoadMoreRequested());
    }
  }

  // โหลดเมนูตามคำค้นหาและหมวดที่เลือกอยู่ (ไม่มีคำค้นหา = ทั้งหมดของหมวด)
  void _loadFoods(String categoryId) {
    final foodBloc = context.read<FoodBloc>();
    foodBloc.add(
      _query.isEmpty
          ? FetchFoodByCategoryEvent(categoryId)
          : SearchFoodEvent(_query, categoryId: categoryId),
    );
  }

  @override
  void initState() {
    super.initState();
    final selectedId = context
        .read<CategoryBloc>()
        .state
        .selectedId; // อ่าน id ของ CategoryBloc
    context.read<FoodBloc>().add(
      FetchFoodByCategoryEvent(selectedId),
    ); // ดึงข้อมูลตาม food by CategoryBloc
  }

  // ดึงลงเพื่อโหลดแบนเนอร์และเมนูใหม่ ถ้ากำลังค้นหาอยู่ก็ค้นหาคำเดิมซ้ำ
  Future<void> _refresh() async {
    final foodBloc = context.read<FoodBloc>();
    final selectedId = context.read<CategoryBloc>().state.selectedId;

    context.read<BannerBloc>().add(FetchBannersEvent());
    final done = foodBloc.stream.firstWhere(
      (state) => state is FoodLoaded || state is FoodError,
    );
    _loadFoods(selectedId);
    await done;
  }

  // หน้า See More ใช้หมวดที่เลือกร่วมกับหน้านี้ (CategoryBloc ตัวเดียวกัน)
  // กลับมาแล้วอัปเดตเงียบ ๆ เผื่อมีการลบสูตร/รีวิวใหม่ที่ทำให้อันดับเปลี่ยน
  Future<void> _openSeeMore() async {
    final foodBloc = context.read<FoodBloc>();
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<CategoryBloc>(),
          child: RecommendedPage(initialQuery: _query),
        ),
      ),
    );
    if (!mounted) return;
    foodBloc.add(FoodSilentRefreshRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: MultiBlocListener(
            listeners: [
              BlocListener<FoodBloc, FoodState>(
                listener: (context, state) {
                  if (state is! FoodLoaded) return;
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _fillRecommended(),
                  );
                },
              ),
              // เพิ่งซื้อสูตรที่อยู่ใน 6 อันดับ = การ์ดหายไป ต้องเติมอันดับถัดไป
              BlocListener<PurchasedRecipesBloc, PurchasedRecipesState>(
                listener: (context, state) => _fillRecommended(),
              ),
            ],
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SearchBarWidget(
                    onSearch: (query) {
                      // ล้างคำค้นหา = กลับไปแสดงตามหมวดที่เลือกไว้
                      // มีคำค้นหา = ค้นหาในขอบเขตของหมวดที่เลือกอยู่
                      _query = query;
                      _loadFoods(context.read<CategoryBloc>().state.selectedId);
                    },
                  ),

                  const SizedBox(height: 20),

                  const HomeBanner(),

                  const SizedBox(height: 25),

                  // เปลี่ยนหมวดตอนค้นหาอยู่ ต้องค้นหาคำเดิมในหมวดใหม่ ไม่ใช่โหลดทั้งหมวด
                  CategoryList(onCategoryChanged: _loadFoods),

                  // แถบหมวดเผื่อที่ให้เงาไว้ข้างล่างแล้ว 12
                  const SizedBox(height: 13),

                  SectionTitle(onSeeMore: _openSeeMore),

                  const SizedBox(height: 20),

                  const FoodGridSection(maxItems: _maxRecommended),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
