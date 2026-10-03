import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/food_detail/food_detail_colors.dart';

/// ปุ่มตะกร้าที่เด้งได้ ใช้ key ตัวเดียวทั้งหาตำแหน่งปลายทางและสั่งเด้ง
class CartBounce extends StatefulWidget {
  const CartBounce({super.key, required this.child});

  final Widget child;

  @override
  State<CartBounce> createState() => CartBounceState();
}

class CartBounceState extends State<CartBounce>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1, end: 1.3), weight: 35),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.3,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.elasticOut)),
      weight: 65,
    ),
  ]).animate(_controller);

  Rect? get globalRect {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void bounce() => _controller.forward(from: 0);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}

/// ลอยรูปอาหารจาก [from] ไปลง [to] เป็นเส้นโค้ง ย่อเล็กลงระหว่างทาง
/// เสร็จแล้วค่อยเรียก [onArrived] (ใช้สั่งตะกร้าเด้ง)
void flyToCart({
  required BuildContext context,
  required String imageUrl,
  required Rect from,
  required Rect to,
  VoidCallback? onArrived,
}) {
  final overlay = Overlay.of(context);
  late final OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => _FlyingImage(
      imageUrl: imageUrl,
      from: from,
      to: to,
      onDone: () {
        entry.remove();
        onArrived?.call();
      },
    ),
  );
  overlay.insert(entry);
}

class _FlyingImage extends StatefulWidget {
  const _FlyingImage({
    required this.imageUrl,
    required this.from,
    required this.to,
    required this.onDone,
  });

  final String imageUrl;
  final Rect from;
  final Rect to;
  final VoidCallback onDone;

  @override
  State<_FlyingImage> createState() => _FlyingImageState();
}

class _FlyingImageState extends State<_FlyingImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final start = widget.from.center;
    final end = widget.to.center;
    // จุดควบคุมอยู่เหนือเส้นตรง ทำให้ลอยเป็นวงโค้งก่อนตกลงตะกร้า
    final control = Offset(
      (start.dx + end.dx) / 2,
      math.min(start.dy, end.dy) - 80,
    );
    final startSize = widget.from.shortestSide;
    final endSize = widget.to.shortestSide * 0.4;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = Curves.easeInOutCubic.transform(_controller.value);
          final position = _quadraticBezier(start, control, end, t);
          final size = startSize + (endSize - startSize) * t;
          // จางลงช่วงท้ายตอนกำลังตกลงตะกร้า
          final opacity = t < 0.8 ? 1.0 : 1 - (t - 0.8) / 0.2;

          return Stack(
            children: [
              Positioned(
                left: position.dx - size / 2,
                top: position.dy - size / 2,
                width: size,
                height: size,
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Transform.rotate(angle: t * math.pi / 3, child: child),
                ),
              ),
            ],
          );
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: widget.imageUrl.isEmpty
                ? const _PlaceholderIcon()
                : Image.network(
                    widget.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _PlaceholderIcon(),
                  ),
          ),
        ),
      ),
    );
  }

  static Offset _quadraticBezier(Offset p0, Offset p1, Offset p2, double t) {
    final u = 1 - t;
    return p0 * (u * u) + p1 * (2 * u * t) + p2 * (t * t);
  }
}

// ImagePlaceholder สูงตายตัว 240 ใช้ในวงกลมที่หดลงเรื่อย ๆ ไม่ได้
class _PlaceholderIcon extends StatelessWidget {
  const _PlaceholderIcon();

  @override
  Widget build(BuildContext context) {
    return const FittedBox(
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Icon(Icons.restaurant, color: FoodDetailColors.accentOrange),
      ),
    );
  }
}
