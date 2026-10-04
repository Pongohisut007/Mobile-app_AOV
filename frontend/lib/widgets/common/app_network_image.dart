import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// รูปจาก URL ที่ใช้ทั้งแอป
/// - เก็บลงเครื่อง (disk) + RAM: เปิดซ้ำ/เปิดแอปใหม่ก็ไม่ต้องโหลดอีก
/// - ถอดรหัสแค่ขนาดที่แสดงจริง: รูป 4000px ในการ์ด 200px ไม่กิน RAM/เวลาเกินจำเป็น
/// - มีพื้นสีเทาระหว่างโหลด แล้วค่อย ๆ จางเข้า
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage(
    this.url, {
    super.key,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorBuilder,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;

  /// แสดงระหว่างโหลด (ไม่ส่ง = พื้นสีเทาอ่อน)
  final Widget? placeholder;

  /// แสดงตอนโหลดไม่ได้ (ไม่ส่ง = ไอคอนรูปเสีย)
  final WidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) return _error(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return CachedNetworkImage(
          imageUrl: url,
          fit: fit,
          width: width,
          height: height,
          // width: double.infinity = เต็มกรอบ ใช้ขนาดกรอบจริงแทน
          memCacheWidth: decodeWidth(
            context,
            _finiteOr(width, constraints.maxWidth),
            _finiteOr(height, constraints.maxHeight),
          ),
          fadeInDuration: const Duration(milliseconds: 150),
          fadeOutDuration: Duration.zero,
          placeholder: (_, _) =>
              placeholder ?? ColoredBox(color: Colors.grey.shade200),
          errorWidget: (context, _, _) => _error(context),
        );
      },
    );
  }

  static double _finiteOr(double? value, double fallback) =>
      value != null && value.isFinite ? value : fallback;

  Widget _error(BuildContext context) =>
      errorBuilder?.call(context) ??
      ColoredBox(
        color: Colors.grey.shade200,
        child: Center(
          child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade500),
        ),
      );

  /// ความกว้างที่ควรถอดรหัสรูป (pixel จริงของจอ)
  /// ใช้ด้านที่ยาวกว่าของกรอบ เพื่อให้ BoxFit.cover ยังคมแม้รูปกับกรอบสัดส่วนต่างกัน
  /// ไม่รู้ขนาดกรอบ = null (ถอดรหัสเต็มขนาด)
  static int? decodeWidth(
    BuildContext context,
    double logicalWidth,
    double logicalHeight,
  ) {
    final sides = [
      logicalWidth,
      logicalHeight,
    ].where((side) => side.isFinite && side > 0);
    if (sides.isEmpty) return null;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return (sides.reduce(math.max) * pixelRatio).round();
  }
}

/// ImageProvider แบบมี cache สำหรับที่ต้องใช้ provider (เช่น CircleAvatar)
/// ส่ง logicalSize = ขนาดที่แสดง จะถอดรหัสแค่ขนาดนั้น
ImageProvider appNetworkImageProvider(
  BuildContext context,
  String url, {
  double? logicalSize,
}) {
  final provider = CachedNetworkImageProvider(url);
  if (logicalSize == null) return provider;
  final pixels = (logicalSize * MediaQuery.devicePixelRatioOf(context)).round();
  return ResizeImage(provider, width: pixels, policy: ResizeImagePolicy.fit);
}
