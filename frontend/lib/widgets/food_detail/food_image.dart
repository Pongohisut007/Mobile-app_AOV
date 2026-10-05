import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/common/app_network_image.dart';
import 'package:flutter_application_1/widgets/common/recipe_hero.dart';
import 'package:flutter_application_1/widgets/food_detail/food_detail_colors.dart';
import 'package:flutter_application_1/widgets/food_detail/image_placeholder.dart';

/// รูปหัวหน้ารายละเอียด: เต็มความกว้าง ครอปแบบ cover มุมล่างโค้ง
/// ครอบ Hero ด้วย tag = id สูตร ให้รูปบินมาจากการ์ดหน้า Home
class FoodImage extends StatelessWidget {
  const FoodImage({
    super.key,
    required this.heroTag,
    required this.imageUrl,
    this.height = defaultHeight,
  });

  static const double defaultHeight = 320;

  final String heroTag;
  final String imageUrl;
  final double height;

  @override
  Widget build(BuildContext context) {
    return RecipeHero(
      recipeId: heroTag,
      imageUrl: imageUrl,
      borderRadius: RecipeHero.headerRadius,
      child: ClipRRect(
        borderRadius: RecipeHero.headerRadius,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: imageUrl.isEmpty
              ? const ImagePlaceholder()
              : AppNetworkImage(
                  imageUrl,
                  errorBuilder: (_) => const ImagePlaceholder(),
                  // รูปเดียวกับการ์ดหน้า Home ส่วนใหญ่อยู่ใน cache แล้ว แทบไม่เห็นพื้นนี้
                  placeholder: const ColoredBox(
                    color: FoodDetailColors.imageBackground,
                  ),
                ),
        ),
      ),
    );
  }
}
