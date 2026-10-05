import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/food_detail/food_detail_colors.dart';

/// พื้นเทาพร้อมไอคอนแทนรูป เวลาไม่มีรูป หรือโหลดรูปไม่สำเร็จ (เต็มกรอบที่ได้รับ)
class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: FoodDetailColors.imageBackground,
      child: Center(
        child: Icon(Icons.restaurant, size: 64, color: Colors.grey.shade500),
      ),
    );
  }
}
