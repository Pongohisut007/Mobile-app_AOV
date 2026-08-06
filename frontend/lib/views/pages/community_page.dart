import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/bloc/category/category_bloc.dart';
import 'package:flutter_application_1/bloc/category/category_event.dart';
import 'package:flutter_application_1/bloc/category/category_state.dart';
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

    // CategoryBloc โหลด category ไปแล้วตอนสร้าง route
    // ยิงซ้ำเฉพาะกรณีที่ยังไม่มีข้อมูลและไม่ได้กำลังโหลดอยู่ (เช่นรอบก่อนพลาด)
    final categoryBloc = context.read<CategoryBloc>();
    final state = categoryBloc.state;
    if (state is! CategoryLoaded && state is! CategoryLoading) {
      categoryBloc.add(FetchCategoriesEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: BlocBuilder<CategoryBloc, CategoryState>(
            builder: (context, state) {
              if (state is CategoryLoading || state is CategoryInitial) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (state is CategoryError) {
                return Center(
                  child: Text(
                    state.message,
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              if (state is! CategoryLoaded || state.categories.isEmpty) {
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
            },
          ),
        ),
      ),
    );
  }
}