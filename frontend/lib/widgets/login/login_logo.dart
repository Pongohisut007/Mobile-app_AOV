import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

    return SizedBox(
      height: screenSize.height * heightFactor,
      child: Stack(
        children: [
          // ปุ่มย้อนกลับ
          Positioned(
            left: 8,
            top: 8,
            child: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back, size: 35),
              color: Colors.white,
              padding: EdgeInsets.zero,
            ),
          ),
          // Logo
          Center(
            child: SvgPicture.asset(
              'assets/images/recipy-logo.svg',
              width: screenSize.width * widthFactor,
              height: screenSize.width * widthFactor,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
