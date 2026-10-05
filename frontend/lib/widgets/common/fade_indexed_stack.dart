import 'package:flutter/material.dart';

/// IndexedStack ที่สลับหน้าแบบจางเข้า + ขยับขึ้นนิดเดียว (แบบ fade through ของ Material)
///
/// ทุกหน้ายังอยู่ใน tree ตลอดเหมือน IndexedStack: ตำแหน่งที่เลื่อนไว้/ข้อมูลที่โหลดแล้วไม่หาย
/// หน้าที่ไม่ได้แสดง: ไม่วาด, ไม่รับการแตะ, หยุดแอนิเมชัน และไม่ร่วมบินกับ Hero
class FadeIndexedStack extends StatefulWidget {
  const FadeIndexedStack({
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 220),
    super.key,
  });

  final int index;
  final List<Widget> children;
  final Duration duration;

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  // เปิดแอปมาครั้งแรกแสดงทันที ไม่ต้องจาง
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: 1,
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, 0.015),
    end: Offset.zero,
  ).animate(_curve);

  @override
  void didUpdateWidget(covariant FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;
    if (oldWidget.index != widget.index) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (final (index, child) in widget.children.indexed)
          _buildChild(child, isCurrent: index == widget.index),
      ],
    );
  }

  Widget _buildChild(Widget child, {required bool isCurrent}) {
    return Offstage(
      offstage: !isCurrent,
      child: TickerMode(
        enabled: isCurrent,
        child: HeroMode(
          enabled: isCurrent,
          child: isCurrent
              ? FadeTransition(
                  opacity: _curve,
                  child: SlideTransition(position: _slide, child: child),
                )
              // ห่อด้วยชั้นเดิมให้โครง widget เหมือนกัน สลับแท็บแล้ว state ของหน้าไม่ถูกสร้างใหม่
              : FadeTransition(
                  opacity: kAlwaysCompleteAnimation,
                  child: SlideTransition(
                    position: const AlwaysStoppedAnimation(Offset.zero),
                    child: child,
                  ),
                ),
        ),
      ),
    );
  }
}
