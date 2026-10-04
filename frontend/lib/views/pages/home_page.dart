import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/banner/banner_bloc.dart';
import 'package:flutter_application_1/bloc/banner/banner_event.dart';
import 'package:flutter_application_1/bloc/category/category_bloc.dart';
import 'package:flutter_application_1/bloc/category/category_state.dart';
import 'package:flutter_application_1/bloc/food/food_bloc.dart';
import 'package:flutter_application_1/bloc/food/food_event.dart';
import 'package:flutter_application_1/bloc/food/food_state.dart';
import 'package:flutter_application_1/bloc/purchased_recipes/purchased_recipes_bloc.dart';
import 'package:flutter_application_1/views/pages/food_detail_page.dart';
import 'package:flutter_application_1/widgets/home/category_list.dart';
import 'package:flutter_application_1/widgets/home/food_card.dart';
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
  // คำค้นหาปัจจุบัน ใช้ค้นหาซ้ำตอนเปลี่ยนหมวดและตอนดึงรีเฟรช
  String _query = '';

  final _scrollController = ScrollController();

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
    _scrollController.addListener(_maybeLoadMore);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
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

                  const SizedBox(height: 25),

                  const SectionTitle(),

                  const SizedBox(height: 20),

                  BlocBuilder<FoodBloc, FoodState>(
                    builder: (context, state) {
                      if (state is FoodInitial) {
                        return const Center(child: Text("Initial Loading..."));
                      }
                      if (state is FoodLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state is FoodLoaded) {
                        // ซ่อนสูตรที่ซื้อแล้ว ไปเปิดได้จากหน้า "สูตรที่ซื้อแล้ว" แทน
                        final purchased = context
                            .watch<PurchasedRecipesBloc>()
                            .state;
                        final foods = state.foods
                            .where(
                              (food) => !purchased.isPurchased(food.idfoods),
                            )
                            .toList(growable: false);

                        // หน้านี้ถูกซ่อนหมดแต่ยังมีหน้าถัดไป = รอโหลดหน้าถัดไปก่อน
                        if (foods.isEmpty && state.hasMore) {
                          return _LoadMoreFooter(
                            state: state,
                            onRetry: () => context.read<FoodBloc>().add(
                              FoodLoadMoreRequested(),
                            ),
                          );
                        }

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
                        final categoryState = context
                            .read<CategoryBloc>()
                            .state;
                        final selectedCategoryName =
                            categoryState is CategoryLoaded
                            ? categoryState.categories
                                  .where(
                                    (category) =>
                                        category.id == categoryState.selectedId,
                                  )
                                  .map((category) => category.name)
                                  .firstOrNull
                            : null;

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            // < 600 มือถือ = 2 คอลัมน์, >= 600 iPad = 3 คอลัมน์
                            final crossAxisCount = width >= 900
                                ? 4
                                : (width >= 600 ? 3 : 2);

                            final grid = GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: foods.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
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
                            );

                            return Column(
                              children: [
                                grid,
                                _LoadMoreFooter(
                                  state: state,
                                  onRetry: () => context.read<FoodBloc>().add(
                                    FoodLoadMoreRequested(),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      }
                      // handle error state
                      if (state is FoodError) {
                        return Center(child: Text(state.message));
                      }
                      // return empty widget
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
