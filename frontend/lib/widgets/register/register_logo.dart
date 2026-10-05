import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/common/auth_style.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// ส่วนหัวโลโก้ของหน้า register (ใช้เป็น sliver ใน CustomScrollView)
/// เปิดมาขนาดเท่าหน้า login แล้วค่อย ๆ ย่อเมื่อเลื่อนลง
/// จนเหลือแถบเล็กที่มีปุ่มย้อนกลับค้างอยู่ด้านบน
class RegisterLogoHeader extends StatelessWidget {
  const RegisterLogoHeader({
    // ค่าเดียวกับ LoginLogo ในหน้า login
    this.heightFactor = 0.32,
    this.widthFactor = 0.38,
    super.key,
  });

  final double heightFactor;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    return SliverPersistentHeader(
      pinned: true,
      delegate: _RegisterLogoHeaderDelegate(
        maxHeight: screenSize.height * heightFactor,
        maxLogoSize: screenSize.width * widthFactor,
      ),
    );
  }
}

class _RegisterLogoHeaderDelegate extends SliverPersistentHeaderDelegate {
  _RegisterLogoHeaderDelegate({
    required double maxHeight,
    required this.maxLogoSize,
  }) : maxHeight = maxHeight < _minHeight ? _minHeight : maxHeight;

  static const _minHeight = 64.0;
  static const _minLogoSize = 40.0;

  final double maxHeight;
  final double maxLogoSize;

  @override
  double get minExtent => _minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final range = maxExtent - minExtent;
    final progress = range <= 0 ? 1.0 : (shrinkOffset / range).clamp(0.0, 1.0);
    // โลโก้ต้องไม่ใหญ่กว่าความสูงของแถบตอนนั้น (เช่นจอแนวนอน)
    final currentHeight = (maxExtent - shrinkOffset).clamp(
      minExtent,
      maxExtent,
    );
    final logoSize = lerpDouble(
      maxLogoSize,
      _minLogoSize,
      progress,
    )!.clamp(_minLogoSize, currentHeight - 16).toDouble();

    // พื้นทึบไล่สีเดียวกับหน้า ฟอร์มที่เลื่อนลอดใต้แถบจะได้ไม่โผล่ทะลุ
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AuthStyle.gradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: SvgPicture.asset(
              'assets/images/recipy-logo.svg',
              width: logoSize,
              height: logoSize,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            left: 8,
            top: 8,
            child: IconButton(
              // maybePop ให้ PopScope ของหน้า register พากลับไปหน้า login
              onPressed: () {
                Navigator.maybePop(context);
              },
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              icon: const Icon(Icons.arrow_back, size: 32),
              color: Colors.white,
              padding: EdgeInsets.zero,
            ),
          ),
          const Positioned(top: 12, right: 12, child: AuthLanguageButton()),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _RegisterLogoHeaderDelegate oldDelegate) =>
      oldDelegate.maxHeight != maxHeight ||
      oldDelegate.maxLogoSize != maxLogoSize;
}
