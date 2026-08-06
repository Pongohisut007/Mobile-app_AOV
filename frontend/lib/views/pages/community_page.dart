import 'package:flutter/material.dart';
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
    // 1 ตอนทำ จุดนี้เปิดแค่ 1 file พอ file_bloc ยกเว้นมี input เข้ามาต้องดู file_state ด้วย
    context.read<CategoryBloc>().add(FetchCategoriesEvent());
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      // 2
      body: BlocBuilder<CategoryBloc, CategoryState>(
        builder: (context, state) {
          if (state is CategoryLoaded) {
            return ListView.builder(
              // 3
              itemCount: state.categories.length,
              // 4
              itemBuilder: (context, index) {
              // 5
              final test = state.categories[index];
              return 
              // 6 ข้อมูลจุดนี้ต้องสอดคล้องกับ models 
              Text(test.name);
              //Text(test.imageUrl ? "ไม่มีข้อมูล"); ใช้งานได้ เพราะ format จาก model ถูก
              //Text(test.name); ใช้งานไม่ได้ เพราะ format จาก model ไม่ถูก
              },
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
