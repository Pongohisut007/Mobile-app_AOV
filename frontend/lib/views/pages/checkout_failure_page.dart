import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';

class CheckoutFailurePage extends StatelessWidget {
  const CheckoutFailurePage({
    super.key,
    required this.message,
    required this.onRetry,
    required this.onBackToCart,
    this.purchasedCount = 0,
  });

  final String message;
  final int purchasedCount;
  final VoidCallback onRetry;
  final VoidCallback onBackToCart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfileColors.background,
      appBar: AppBar(
        backgroundColor: ProfileColors.background,
        foregroundColor: ProfileColors.ink,
        automaticallyImplyLeading: false,
        title: const Text('ชำระเงินไม่สำเร็จ'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE9E3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 60,
                    color: Color(0xFFB34034),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'ยังซื้อสูตรไม่ครบ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ProfileColors.ink,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ProfileColors.muted,
                    fontSize: 16,
                  ),
                ),
                if (purchasedCount > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    'ก่อนเกิดข้อผิดพลาด ซื้อสำเร็จแล้ว $purchasedCount สูตร สูตรที่เหลือยังอยู่ในตะกร้า',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: ProfileColors.ink,
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('ลองใหม่'),
                    style: FilledButton.styleFrom(
                      backgroundColor: ProfileColors.ink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onBackToCart,
                  child: const Text('กลับไปตะกร้า'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
