import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/cart/cart_bloc.dart';
import 'package:flutter_application_1/bloc/cart/cart_event.dart';
import 'package:flutter_application_1/bloc/cart/cart_state.dart';
import 'package:flutter_application_1/bloc/favorite/favorite_bloc.dart';
import 'package:flutter_application_1/bloc/favorite/favorite_event.dart';
import 'package:flutter_application_1/bloc/favorite/favorite_state.dart';
import 'package:flutter_application_1/models/food.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_application_1/routes/app_routes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FoodCard extends StatelessWidget {
  final Food food;
  final VoidCallback? onTap;

  const FoodCard({super.key, required this.food, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: _FavoriteButton(recipeId: food.idfoods), //หัวใจ
            ),
            Expanded(
              child: Center(
                child: Image.network(
                  food.filePathImage,
                  webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.fastfood,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              food.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                Text(
                  food.category,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                _AddToCartButton(food: food), // add
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// หัวใจ กดสลับบันทึก/เอาออกจาก favorites
class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.recipeId});

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
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.redAccent : Colors.grey.shade400,
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
