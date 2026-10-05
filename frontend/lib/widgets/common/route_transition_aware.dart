import 'dart:async';

import 'package:flutter/widgets.dart';

/// ให้หน้ารู้ว่าแอนิเมชันเปิดหน้า (เลื่อนเข้า/Hero) จบหรือยัง
///
/// ระหว่างเลื่อนหน้า ถ้าผลจาก API มาถึงแล้ว build เนื้อหาก้อนใหญ่ทันที เฟรมจะตก หน้าดูสะดุด
/// mixin นี้ให้เริ่มยิง API ได้ทันทีเหมือนเดิม แต่เอาผลไปแสดงหลังแอนิเมชันจบ
/// (ปกติ API ช้ากว่าแอนิเมชัน 300ms อยู่แล้ว ผู้ใช้จึงแทบไม่ต้องรอเพิ่ม)
///
/// หน้าที่ไม่มีแอนิเมชันเปิด (หน้าแรกของแอป/หน้าที่อยู่ในแท็บ) ถือว่าจบแล้วตั้งแต่แรก
mixin RouteTransitionAware<T extends StatefulWidget> on State<T> {
  final Completer<void> _transitionDone = Completer<void>();
  Animation<double>? _routeAnimation;

  /// แอนิเมชันเปิดหน้าจบแล้ว (ถ้าจบระหว่างที่หน้าแสดงอยู่ หน้าจะ build ใหม่ให้อีกรอบ)
  bool get isRouteTransitionDone => _transitionDone.isCompleted;

  Future<void> get routeTransitionDone => _transitionDone.future;

  /// รอทั้งผลของ [future] และแอนิเมชันเปิดหน้า แล้วค่อยคืนผล (error ก็รอเหมือนกัน)
  /// แอนิเมชันจบไปแล้ว = คืนผลทันทีที่ได้ ไม่ช้าลงเลย
  Future<R> afterRouteTransition<R>(Future<R> future) async {
    try {
      final result = await future;
      await _transitionDone.future;
      return result;
    } catch (_) {
      await _transitionDone.future;
      rethrow;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_transitionDone.isCompleted) return;

    final route = ModalRoute.of(context);
    final animation = route?.animation;
    if (animation == _routeAnimation) return;
    _routeAnimation?.removeStatusListener(_onRouteAnimationStatus);
    _routeAnimation = animation;

    // เฟรมแรกของหน้าที่เพิ่ง push จะ build แบบซ่อน (offstage) ไว้วัดตำแหน่ง Hero
    // เฟรมนั้น animation รายงานว่า completed ทั้งที่ยังไม่เริ่มเลื่อน จึงต้องไม่เชื่อ
    if (animation == null || (animation.isCompleted && !route!.offstage)) {
      // ยังอยู่ในขั้นสร้างหน้า แค่ตั้งค่าไว้ build รอบแรกจะเห็นเอง (ห้าม setState ตรงนี้)
      _transitionDone.complete();
      return;
    }
    animation.addStatusListener(_onRouteAnimationStatus);
  }

  void _onRouteAnimationStatus(AnimationStatus status) {
    // dismissed = ปัดย้อนกลับก่อนเปิดเสร็จ ก็ไม่ต้องรออะไรต่อแล้ว
    if (!status.isCompleted && !status.isDismissed) return;
    _routeAnimation?.removeStatusListener(_onRouteAnimationStatus);
    if (_transitionDone.isCompleted) return;
    _transitionDone.complete();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onRouteAnimationStatus);
    super.dispose();
  }
}
