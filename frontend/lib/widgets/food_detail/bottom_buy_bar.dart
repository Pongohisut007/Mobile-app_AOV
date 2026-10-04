import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/food_detail/food_detail_colors.dart';
import 'package:flutter_application_1/widgets/food_detail/fly_to_cart.dart';

class BottomBuyBar extends StatelessWidget {
  const BottomBuyBar({
    super.key,
    required this.onCartPressed,
    required this.onBuyPressed,
    this.buyLabel = 'Buy Now',
    this.cartKey,
    this.isLoading = false,
  });

  /// กำลังเพิ่มลงตะกร้า: แสดงตัวหมุนแทนข้อความ
  final bool isLoading;

  final VoidCallback onCartPressed;
  // null = ยังกดไม่ได้ (โหลดเมนูไม่เสร็จ หรือกำลังเพิ่มลงตะกร้า)
  final VoidCallback? onBuyPressed;
  final String buyLabel;

  /// ปลายทางของรูปที่ลอยลงตะกร้า และใช้สั่งปุ่มตะกร้าเด้ง
  final GlobalKey<CartBounceState>? cartKey;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.all(20),
      child: Row(
        children: [
          CartBounce(
            key: cartKey,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: onCartPressed,
                icon: const Icon(
                  Icons.shopping_bag_outlined,
                  color: FoodDetailColors.primaryRed,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 58,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      FoodDetailColors.primaryRed,
                      FoodDetailColors.accentOrange,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: FoodDetailColors.primaryRed.withValues(
                        alpha: 0.35,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: onBuyPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.transparent,
                    disabledForegroundColor: Colors.white70,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          buyLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
