import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/food_detail/food_detail_colors.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.header});

  /// รูปหัวหน้าที่รู้อยู่แล้ว (จากการ์ดที่กดเข้ามา) โชว์ระหว่างโหลดส่วนที่เหลือ
  /// วางตำแหน่งเดียวกับหัวหน้าจริง ตอนโหลดเสร็จรูปจะไม่กระโดด
  final Widget? header;

  static const _spinner = CircularProgressIndicator(
    color: FoodDetailColors.primaryRed,
    strokeWidth: 3,
  );

  @override
  Widget build(BuildContext context) {
    final header = this.header;
    if (header == null) return const Center(child: _spinner);

    return SafeArea(
      child: Column(
        children: [
          header,
          const Expanded(child: Center(child: _spinner)),
        ],
      ),
    );
  }
}
