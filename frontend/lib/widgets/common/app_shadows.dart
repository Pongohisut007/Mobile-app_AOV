import 'package:flutter/material.dart';

/// เงาที่ใช้ร่วมกันทั้งแอป แก้ที่นี่ที่เดียวแล้วเปลี่ยนทุกหน้า
abstract final class AppShadows {
  /// การ์ด/ปุ่มสีขาวที่วางบนพื้นหลัง: เงาดำจาง ๆ ฟุ้งลงล่างนิดหน่อย
  static const card = [
    BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  /// ของชิ้นเล็ก (ชิป ปุ่มหมวด) ใช้เงาที่แคบกว่าการ์ด
  static const chip = [
    BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 3)),
  ];
}

/// ครอบ Material/InkWell ที่ตัดมุมโค้ง (clipBehavior) ให้มีเงา
/// เงาต้องอยู่นอกส่วนที่ถูกตัด ไม่งั้นหายไปพร้อมมุมโค้ง
class ShadowBox extends StatelessWidget {
  const ShadowBox({
    required this.borderRadius,
    required this.child,
    this.shadows = AppShadows.card,
    super.key,
  });

  final BorderRadiusGeometry borderRadius;
  final List<BoxShadow> shadows;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: borderRadius, boxShadow: shadows),
      child: child,
    );
  }
}
