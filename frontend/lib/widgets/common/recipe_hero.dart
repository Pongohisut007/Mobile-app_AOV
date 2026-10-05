import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/common/app_network_image.dart';

/// Hero ของรูปสูตร: การ์ด (หน้า Home / All Recipes) ↔ รูปหัวหน้ารายละเอียด
/// และการ์ด ↔ การ์ด ตอนย้อนจาก All Recipes กลับหน้า Home
///
/// - ระหว่างบินวาดรูปเองแทนการใช้ widget ของหน้าปลายทาง เพราะ AppNetworkImage
///   ถอดรหัสรูปตามขนาดกรอบ กรอบโตขึ้นทุกเฟรม = ถอดรหัสใหม่ทุกเฟรม รูปกะพริบ
/// - มุมโค้งของแต่ละฝั่งต่างกัน ค่อย ๆ เปลี่ยนไปพร้อมกับการบิน
/// - บินเฉพาะรูปที่มองเห็นบนจอ ใบที่เลื่อนพ้นจอไปแล้วไม่บิน (ไม่งั้นรูปลอยเข้า/ออกขอบจอ)
class RecipeHero extends StatefulWidget {
  const RecipeHero({
    required this.recipeId,
    required this.imageUrl,
    required this.borderRadius,
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

  /// มุมโค้งของรูปฝั่งนี้ ใช้ไล่มุมระหว่างบิน
  final BorderRadius borderRadius;
  final Widget child;

  @override
  State<RecipeHero> createState() => _RecipeHeroState();
}

class _RecipeHeroState extends State<RecipeHero> {
  // ทุก Scrollable ที่ครอบรูปนี้อยู่ (grid ข้างใน + หน้าที่เลื่อนได้ข้างนอก)
  final List<ScrollPosition> _positions = [];
  bool _isVisible = true;
  bool _checkScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final positions = <ScrollPosition>[];
    var scrollable = Scrollable.maybeOf(context);
    while (scrollable != null) {
      positions.add(scrollable.position);
      scrollable = Scrollable.maybeOf(scrollable.context);
    }
    _listenTo(positions);
    _scheduleVisibilityCheck();
  }

  @override
  void didUpdateWidget(covariant RecipeHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ขนาด/ตำแหน่งอาจเปลี่ยน (เช่น grid จัดเรียงใหม่)
    _scheduleVisibilityCheck();
  }

  void _listenTo(List<ScrollPosition> positions) {
    for (final position in _positions) {
      position.removeListener(_checkVisibility);
    }
    _positions
      ..clear()
      ..addAll(positions);
    for (final position in _positions) {
      position.addListener(_checkVisibility);
    }
  }

  @override
  void dispose() {
    _listenTo(const []);
    super.dispose();
  }

  // ต้องรอ layout ก่อนถึงจะรู้ตำแหน่ง
  void _scheduleVisibilityCheck() {
    if (_checkScheduled) return;
    _checkScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScheduled = false;
      _checkVisibility();
    });
  }

  void _checkVisibility() {
    if (!mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return;

    // เห็นบนจอ = ทับกับจอ และทับกับกรอบของทุก Scrollable ที่ครอบอยู่
    var visibleArea = Offset.zero & MediaQuery.sizeOf(context);
    for (final position in _positions) {
      final viewport = position.context.notificationContext?.findRenderObject();
      if (viewport is RenderBox && viewport.hasSize && viewport.attached) {
        visibleArea = visibleArea.intersect(
          viewport.localToGlobal(Offset.zero) & viewport.size,
        );
      }
    }
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final intersection = rect.intersect(visibleArea);
    final isVisible = intersection.width > 0 && intersection.height > 0;

    if (isVisible != _isVisible) setState(() => _isVisible = isVisible);
  }

  @override
  Widget build(BuildContext context) {
    // HeroMode ปิด = Hero ตัวนี้ไม่ร่วมบิน ฝั่งตรงข้ามก็แค่โผล่ขึ้นมาตามแอนิเมชันเปลี่ยนหน้า
    return HeroMode(
      enabled: _isVisible,
      child: Hero(
        tag: widget.recipeId,
        // บินเป็นเส้นตรง (ค่าเริ่มต้นของ MaterialApp เป็นเส้นโค้ง ดูเหวี่ยงตอนรูปขยายขึ้นด้านบน)
        createRectTween: (begin, end) => RectTween(begin: begin, end: end),
        flightShuttleBuilder: _buildShuttle,
        // ปัดขอบซ้ายเพื่อย้อนกลับ รูปก็บินกลับตามนิ้ว
        transitionOnUserGestures: true,
        child: widget.child,
      ),
    );
  }

  Widget _buildShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    // animation: 0 = หน้าล่าง, 1 = หน้าบน (ทั้งตอน push และ pop)
    final isPush = direction == HeroFlightDirection.push;
    final lowerRadius = _radiusOf(isPush ? fromHeroContext : toHeroContext);
    final upperRadius = _radiusOf(isPush ? toHeroContext : fromHeroContext);
    final fromSize = _sizeOf(fromHeroContext);
    final toSize = _sizeOf(toHeroContext);
    final imageUrl = widget.imageUrl;

    final Widget image;
    if (imageUrl.trim().isEmpty || fromSize == null || toSize == null) {
      image = const ColoredBox(color: RecipeHero._imageBackground);
    } else {
      image = Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: RecipeHero._imageBackground),
          // รูปขนาดฝั่งต้นทาง ถอดรหัสไว้แล้วตอนแสดงอยู่บนจอ โชว์ได้ทันที
          Image(
            image: appNetworkImageProviderForBox(
              flightContext,
              imageUrl,
              fromSize,
            ),
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),
          // รูปขนาดฝั่งปลายทาง ถอดรหัสเสร็จเมื่อไหร่ก็ทับ ภาพจะคมขึ้นโดยไม่กะพริบ
          // ตัวเดียวกับที่ปลายทางใช้ บินถึงแล้วปลายทางได้รูปจาก cache ทันที
          Image(
            image: appNetworkImageProviderForBox(
              flightContext,
              imageUrl,
              toSize,
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
          lowerRadius,
          upperRadius,
          curved.value,
        )!,
        child: child,
      ),
      child: image,
    );
  }

  static BorderRadius _radiusOf(BuildContext heroContext) =>
      heroContext.findAncestorWidgetOfExactType<RecipeHero>()?.borderRadius ??
      BorderRadius.zero;

  static Size? _sizeOf(BuildContext context) {
    final box = context.findRenderObject();
    return box is RenderBox && box.hasSize ? box.size : null;
  }
}
