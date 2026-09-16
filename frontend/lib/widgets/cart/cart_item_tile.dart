import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/cart_item.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';

class CartItemTile extends StatelessWidget {
  const CartItemTile({
    super.key,
    required this.item,
    required this.onRemove,
    required this.isSelected,
    required this.onSelectedChanged,
  });

  final CartItem item;
  final VoidCallback? onRemove;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectedChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox อยู่กึ่งกลางแนวตั้ง
          SizedBox(
            height: 78,
            child: Center(
              child: Checkbox(
                value: isSelected,
                onChanged: onSelectedChanged,
                activeColor: ProfileColors.ink,
                visualDensity: VisualDensity.compact,
                semanticLabel: 'เลือก ${item.title} เพื่อชำระเงิน',
              ),
            ),
          ),
          const SizedBox(width: 4),

          // รูปสินค้า
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 78,
              height: 78,
              child: _CartItemImage(url: item.imageUrl),
            ),
          ),
          const SizedBox(width: 14),

          // ชื่อและราคา
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ProfileColors.ink,
                    fontSize: 15,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.price == 0
                      ? 'Free'
                      : '฿${item.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: ProfileColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          // ปุ่ม X อยู่กึ่งกลางแนวตั้ง
          SizedBox(
            height: 78,
            child: Center(
              child: IconButton(
                onPressed: onRemove,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                constraints: const BoxConstraints(),
                color: ProfileColors.muted,
                icon: const Icon(Icons.close_rounded, size: 18),
                tooltip: 'Remove',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// load image
class _CartItemImage extends StatelessWidget {
  const _CartItemImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;
    if (imageUrl == null) return const _ImagePlaceholder();

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const _ImagePlaceholder(),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFE8E9E2),
      child: Center(
        child: Icon(
          Icons.restaurant_menu_rounded,
          color: ProfileColors.muted,
          size: 30,
        ),
      ),
    );
  }
}
