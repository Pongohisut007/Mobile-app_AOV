import 'package:flutter/material.dart';
import 'package:flutter_application_1/l10n/l10n.dart';
import 'package:flutter_application_1/widgets/common/auth_style.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// ส่วนหัวของหน้า login: โลโก้ + คำบอกว่าแอปทำอะไร
/// ปุ่มย้อนกลับซ้ายบน (มีเมื่อย้อนได้) ปุ่มเปลี่ยนภาษาขวาบน
class LoginLogo extends StatelessWidget {
  const LoginLogo({
    this.heightFactor = 0.24,
    this.widthFactor = 0.28,
    super.key,
  });

  final double heightFactor;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final logoSize = screenSize.width * widthFactor;

    return SizedBox(
      height: screenSize.height * heightFactor,
      child: Stack(
        children: [
          // จอเตี้ย (หรือคำบอกยาวจนตัด 2 บรรทัด) ย่อทั้งก้อนลงแทนการล้นกรอบ
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/images/recipy-logo.svg',
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 10),
                  // คำบอกว่าแอปทำอะไร ตัวใหญ่หนาและมีเงา อ่านชัดบนพื้นไล่สี
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      context.l10n.authTagline,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        shadows: [
                          Shadow(
                            color: Color(0x40000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // เปิดหน้า login เป็นหน้าแรก (ไม่มีหน้าก่อนหน้า) ไม่ต้องมีปุ่มย้อนกลับ
          if (Navigator.canPop(context))
            Positioned(
              left: 8,
              top: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
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
}
