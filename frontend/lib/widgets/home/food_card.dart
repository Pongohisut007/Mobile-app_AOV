import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/common/app_shadows.dart';
import 'package:flutter_application_1/bloc/cart/cart_bloc.dart';
import 'package:flutter_application_1/bloc/cart/cart_event.dart';
import 'package:flutter_application_1/bloc/cart/cart_state.dart';
import 'package:flutter_application_1/bloc/favorite/favorite_bloc.dart';
import 'package:flutter_application_1/bloc/favorite/favorite_event.dart';
import 'package:flutter_application_1/bloc/favorite/favorite_state.dart';
import 'package:flutter_application_1/models/food.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_application_1/routes/app_routes.dart';
import 'package:flutter_application_1/widgets/common/app_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FoodCard extends StatelessWidget {
  final Food food;
  final VoidCallback? onTap;

  const FoodCard({super.key, required this.food, this.onTap});

  // พื้นหลังตอนรูปกำลังโหลด/ไม่มีรูป สีเดียวกับการ์ดหน้า favorite
  static const _imageBackground = Color(0xFFE8E9E2);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      // เงาอยู่นอก ClipRRect ไม่งั้นโดนตัดไปพร้อมมุมโค้ง
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.card,
        ),
        // รูปเต็มขอบบนของการ์ดเหมือนการ์ดหน้า favorite ตัดมุมโค้งตามการ์ด
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: ColoredBox(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // หัวใจลอยทับมุมขวาบนของรูป
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppNetworkImage(
                        food.filePathImage,
                        placeholder: const ColoredBox(color: _imageBackground),
                        errorBuilder: (context) => ColoredBox(
                          color: _imageBackground,
                          child: Icon(
                            Icons.fastfood,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: _FavoriteButton(recipeId: food.idfoods), //หัวใจ
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        food.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(child: _RatingLabel(food: food)),
                          _AddToCartButton(food: food), // add
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ★ 4.5 (12) จากรีวิวที่เผยแพร่ ยังไม่มีรีวิว = ☆ ใหม่ (ไม่ใช่ได้ 0 ดาว)
class _RatingLabel extends StatelessWidget {
  const _RatingLabel({required this.food});

  final Food food;

  @override
  Widget build(BuildContext context) {
    final rating = food.averageRating;
    final hasReviews = rating != null && food.reviewCount > 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          hasReviews ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 18,
          color: Colors.amber,
        ),
        const SizedBox(width: 3),
        Flexible(
          child: Text.rich(
            hasReviews
                ? TextSpan(
                    text: rating.toStringAsFixed(1),
                    children: [
                      TextSpan(
                        text: ' (${food.reviewCount})',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  )
                : const TextSpan(text: 'ใหม่'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

// หัวใจ กดสลับบันทึก/เอาออกจาก favorites
class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.recipeId});

  static const _heartShadows = [
    Shadow(color: Color(0x59000000), blurRadius: 4, offset: Offset(0, 1)),
  ];

  final String recipeId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoriteBloc, FavoriteState>(
      // วาดใหม่เฉพาะตอนสถานะของสูตรใบนี้เปลี่ยน ไม่ใช่ทุกครั้งที่ใบอื่นเปลี่ยน
      buildWhen: (previous, current) =>
          previous.isFavorite(recipeId) != current.isFavorite(recipeId) ||
          previous.isPending(recipeId) != current.isPending(recipeId),
      builder: (context, state) {
        final isFavorite = state.isFavorite(recipeId);

        return IconButton(
          // กดที่หัวใจต้องไม่ไปเปิดหน้ารายละเอียดของการ์ด
          // ไม่ใส่ null ตอนกำลังยิง API เพราะปุ่มที่ปิดอยู่จะปล่อยให้แตะทะลุไปเปิดการ์ด
          onPressed: () async {
            if (state.isPending(recipeId)) return;
            final favoriteBloc = context.read<FavoriteBloc>();
            if (await _requireSignIn(context)) return;
            favoriteBloc.add(FavoriteToggled(recipeId));
          },
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          tooltip: isFavorite ? 'เอาออกจากรายการโปรด' : 'บันทึกลงรายการโปรด',
          // หัวใจลอยอยู่บนรูป ยังไม่กด = หัวใจทึบสีขาว
          // กดแล้ว = หัวใจแดงซ้อนบนหัวใจขาวที่ใหญ่กว่านิด ได้ขอบขาวรอบหัวใจ
          // เงาจาง ๆ ใต้หัวใจขาว กันกลืนกับรูปสีอ่อน
          icon: isFavorite
              ? const Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.favorite,
                      size: 32,
                      color: Colors.white,
                      shadows: _heartShadows,
                    ),
                    Icon(Icons.favorite, size: 26, color: Colors.redAccent),
                  ],
                )
              : const Icon(
                  Icons.favorite,
                  size: 26,
                  color: Colors.white,
                  shadows: _heartShadows,
                ),
        );
      },
    );
  }
}

// ปุ่มเปิด/ปิดสูตรในตะกร้า อยู่ในตะกร้าแล้วไอคอนจะเป็นตะกร้าทึบ กดอีกครั้งเพื่อเอาออก
class _AddToCartButton extends StatelessWidget {
  const _AddToCartButton({required this.food});

  final Food food;

  @override
  Widget build(BuildContext context) {
    final recipeId = food.idfoods;

    return BlocBuilder<CartBloc, CartState>(
      buildWhen: (previous, current) =>
          previous.contains(recipeId) != current.contains(recipeId) ||
          previous.isPending(recipeId) != current.isPending(recipeId),
      builder: (context, state) {
        final inCart = state.contains(recipeId);
        final isPending = state.isPending(recipeId);

        return Material(
          color: Colors.lime,
          shape: const CircleBorder(),
          // ลอยขึ้นจากการ์ดนิดหน่อย ให้รู้ว่ากดได้
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.4),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isPending
                ? null
                : () async {
                    final cartBloc = context.read<CartBloc>();
                    if (await _requireSignIn(context)) return;

                    final cartItem = cartBloc.state.items
                        .where((item) => item.recipeId == recipeId)
                        .firstOrNull;
                    cartBloc.add(
                      cartItem == null
                          ? CartItemAdded(food)
                          : CartItemRemoved(cartItem.id),
                    );
                  },
            child: SizedBox(
              width: 32,
              height: 32,
              child: Center(
                child: isPending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    // ใช้ไอคอนตะกร้าทั้งสองสถานะ ติ๊กถูกดูเหมือนซื้อไปแล้ว
                    : Icon(
                        inCart
                            ? Icons.shopping_cart
                            : Icons.add_shopping_cart_outlined,
                        color: Colors.black,
                        size: 18,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// ตะกร้ากับรายการโปรดผูกกับบัญชี ยังไม่ล็อกอินก็เด้งไปหน้า login ก่อน
/// คืน true เมื่อไปต่อไม่ได้ (ผู้เรียกต้องหยุดทำงานต่อ)
/// อ่าน token จาก secure storage จึงเป็น async ต้องเช็ค mounted หลัง await
Future<bool> _requireSignIn(BuildContext context) async {
  final navigator = Navigator.of(context);
  final accessToken = await TokenStorage().readAccessToken();

  if (accessToken != null && accessToken.trim().isNotEmpty) return false;
  if (!context.mounted) return true;

  navigator.pushNamed(AppRoutes.login);
  return true;
}
