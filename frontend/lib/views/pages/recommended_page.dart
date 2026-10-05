import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/category/category_bloc.dart';
import 'package:flutter_application_1/bloc/food/food_bloc.dart';
import 'package:flutter_application_1/bloc/food/food_event.dart';
import 'package:flutter_application_1/bloc/food/food_state.dart';
import 'package:flutter_application_1/repositories/food_repository.dart';
import 'package:flutter_application_1/widgets/home/category_list.dart';
import 'package:flutter_application_1/widgets/home/food_grid_section.dart';
import 'package:flutter_application_1/widgets/home/search_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// หน้า See More ของ Recommended: สูตร official ทั้งหมด เรียงตามคะแนนรีวิว
/// เหมือนหน้า home แต่ไม่มีแบนเนอร์ และเลื่อนโหลดเพิ่มทีละหน้าได้เรื่อย ๆ
///
/// ต้องมี CategoryBloc ของหน้า home อยู่ด้านบน (ส่งมาด้วย BlocProvider.value)
/// หมวดที่เลือกจึงตรงกันทั้งสองหน้า ส่วนรายการสูตรใช้ FoodBloc ของตัวเอง
class RecommendedPage extends StatelessWidget {
  const RecommendedPage({this.initialQuery = '', super.key});

  /// คำค้นหาที่ค้างอยู่ในหน้า home
  final String initialQuery;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FoodBloc(FoodRepository()),
      child: _RecommendedView(initialQuery: initialQuery),
    );
  }
}

class _RecommendedView extends StatefulWidget {
  const _RecommendedView({required this.initialQuery});

  final String initialQuery;

  @override
  State<_RecommendedView> createState() => _RecommendedViewState();
}

class _RecommendedViewState extends State<_RecommendedView> {
  late String _query = widget.initialQuery.trim();

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadFoods(context.read<CategoryBloc>().state.selectedId);
    _scrollController.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // เลื่อนใกล้ล่างสุด (หรือเนื้อหายังไม่เต็มจอ) = โหลดหน้าถัดไป
  // bloc กันซ้ำเองถ้ากำลังโหลดอยู่หรือหมดแล้ว
  void _maybeLoadMore() {
    if (!mounted || !_scrollController.hasClients) return;
    final state = context.read<FoodBloc>().state;
    // โหลดหน้าถัดไปพลาด ให้ผู้ใช้กดลองใหม่เอง ไม่วนยิงซ้ำ
    if (state is! FoodLoaded || !state.hasMore || state.loadMoreError != null) {
      return;
    }
    if (_scrollController.position.extentAfter < 600) {
      context.read<FoodBloc>().add(FoodLoadMoreRequested());
    }
  }

  // โหลดเมนูตามคำค้นหาและหมวดที่เลือกอยู่ (ไม่มีคำค้นหา = ทั้งหมดของหมวด)
  void _loadFoods(String categoryId) {
    context.read<FoodBloc>().add(
      _query.isEmpty
          ? FetchFoodByCategoryEvent(categoryId)
          : SearchFoodEvent(_query, categoryId: categoryId),
    );
  }

  // ดึงลงเพื่อโหลดเมนูใหม่ ถ้ากำลังค้นหาอยู่ก็ค้นหาคำเดิมซ้ำ
  Future<void> _refresh() async {
    final done = context.read<FoodBloc>().stream.firstWhere(
      (state) => state is FoodLoaded || state is FoodError,
    );
    _loadFoods(context.read<CategoryBloc>().state.selectedId);
    await done;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'All Recipes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.grey.shade100,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          // โหลดหน้าแล้วเนื้อหายังไม่ถึงล่างจอ (เช่น ซ่อนสูตรที่ซื้อแล้วไปเยอะ) ก็โหลดต่อเลย
          child: BlocListener<FoodBloc, FoodState>(
            listener: (context, state) {
              if (state is! FoodLoaded) return;
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _maybeLoadMore(),
              );
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SearchBarWidget(
                    initialQuery: _query,
                    onSearch: (query) {
                      // ล้างคำค้นหา = กลับไปแสดงตามหมวดที่เลือกไว้
                      // มีคำค้นหา = ค้นหาในขอบเขตของหมวดที่เลือกอยู่
                      _query = query;
                      _loadFoods(context.read<CategoryBloc>().state.selectedId);
                    },
                  ),

                  const SizedBox(height: 25),

                  // เปลี่ยนหมวดตอนค้นหาอยู่ ต้องค้นหาคำเดิมในหมวดใหม่ ไม่ใช่โหลดทั้งหมวด
                  CategoryList(onCategoryChanged: _loadFoods),

                  // แถบหมวดเผื่อที่ให้เงาไว้ข้างล่างแล้ว 12
                  const SizedBox(height: 13),

                  const FoodGridSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
