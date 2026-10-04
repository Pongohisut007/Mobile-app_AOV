import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/common/app_network_image.dart';
import 'package:flutter_application_1/widgets/food_detail/food_detail_colors.dart';
import 'package:flutter_application_1/widgets/food_detail/image_placeholder.dart';

/// รูปอาหาร พร้อม Hero animation และ fallback เป็น [ImagePlaceholder]
class FoodImage extends StatelessWidget {
  const FoodImage({super.key, required this.heroTag, required this.imageUrl});

  final String heroTag;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: heroTag,
      child: imageUrl.isEmpty
          ? const ImagePlaceholder()
          : AppNetworkImage(
              imageUrl,
              height: 240,
              fit: BoxFit.contain,
              errorBuilder: (_) => const ImagePlaceholder(),
              // รูปเดียวกับการ์ดหน้า Home ส่วนใหญ่อยู่ใน cache แล้ว ตัวหมุนแทบไม่โผล่
              placeholder: const SizedBox(
                height: 240,
                child: Center(
                  child: CircularProgressIndicator(
                    color: FoodDetailColors.primaryRed,
                  ),
                ),
              ),
            ),
    );
  }
}