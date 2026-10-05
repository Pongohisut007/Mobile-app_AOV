import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/common/app_network_image.dart';

/// Hero ของรูปสูตร: การ์ด (หน้า Home / All Recipes) ↔ รูปหัวหน้ารายละเอียด
///
/// ใช้ตัวนี้ทั้งสองฝั่ง ระหว่างบินจะวาดรูปเองแทนการใช้ widget ของหน้าปลายทาง เพราะ
/// - AppNetworkImage ถอดรหัสรูปตามขนาดกรอบ ถ้าใช้ตรง ๆ กรอบโตขึ้นทุกเฟรม = ถอดรหัสใหม่ทุกเฟรม รูปกะพริบ
/// - มุมโค้งของการ์ด (บน) กับหัวหน้า (ล่าง) ต่างกัน ต้องค่อย ๆ เปลี่ยนไปพร้อมกับการบิน
class RecipeHero extends StatelessWidget {
  const RecipeHero({
    required this.recipeId,
    required this.imageUrl,
    required this.child,
    super.key,
  });

  /// มุมของรูปในการ์ด (การ์ดโค้ง 20 รูปอยู่ส่วนบน)
  static const cardRadius = BorderRadius.vertical(top: Radius.circular(20));

  /// มุมของรูปหัวหน้ารายละเอียด
  static const headerRadius = BorderRadius.vertical(
    bottom: Radius.circular(40),
  );

  static const _imageBackground = Color(0xFFE8E9E2);

  final String recipeId;
  final String imageUrl;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: recipeId,
      // บินเป็นเส้นตรง (ค่าเริ่มต้นของ MaterialApp เป็นเส้นโค้ง ดูเหวี่ยงตอนรูปขยายขึ้นด้านบน)
      createRectTween: (begin, end) => RectTween(begin: begin, end: end),
      flightShuttleBuilder: _buildShuttle,
      child: child,
    );
  }

  Widget _buildShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    // animation: 0 = อยู่ที่การ์ด, 1 = อยู่ที่หัวหน้า (ทั้งตอนไปและตอนย้อนกลับ)
    final isPush = direction == HeroFlightDirection.push;
    final cardSize = _sizeOf(isPush ? fromHeroContext : toHeroContext);
    final headerSize = _sizeOf(isPush ? toHeroContext : fromHeroContext);

    final Widget image;
    if (imageUrl.trim().isEmpty || cardSize == null || headerSize == null) {
      image = const ColoredBox(color: _imageBackground);
    } else {
      image = Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: _imageBackground),
          // รูปขนาดการ์ด ถอดรหัสไว้แล้วตั้งแต่อยู่ในหน้า Home โชว์ได้ทันที
          Image(
            image: appNetworkImageProviderForBox(
              flightContext,
              imageUrl,
              cardSize,
            ),
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),
          // รูปขนาดหัวหน้า ถอดรหัสเสร็จเมื่อไหร่ก็ทับรูปเล็ก ภาพจะคมขึ้นโดยไม่กะพริบ
          // ตัวเดียวกับที่หัวหน้าใช้ บินถึงแล้วหัวหน้าได้รูปจาก cache ทันที
          Image(
            image: appNetworkImageProviderForBox(
              flightContext,
              imageUrl,
              headerSize,
            ),
            fit: BoxFit.cover,
            gaplessPlayback: true,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) =>
                wasSynchronouslyLoaded || frame != null
                ? child
                : const SizedBox.shrink(),
          ),
        ],
      );
    }

    // curve เดียวกับที่ Hero ใช้ขยับกรอบ (ขากลับใช้แบบกลับด้าน) มุมจะเปลี่ยนไปพร้อมขนาด
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.fastOutSlowIn.flipped,
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) => ClipRRect(
        borderRadius: BorderRadius.lerp(
          cardRadius,
          headerRadius,
          curved.value,
        )!,
        child: child,
      ),
      child: image,
    );
  }

  static Size? _sizeOf(BuildContext context) {
    final box = context.findRenderObject();
    return box is RenderBox && box.hasSize ? box.size : null;
  }
}
