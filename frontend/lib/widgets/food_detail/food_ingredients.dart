import 'package:flutter/material.dart';
import 'package:flutter_application_1/l10n/l10n.dart';
import 'package:flutter_application_1/models/recipe_ingredient.dart';

/// รายการวัตถุดิบในหน้ารายละเอียดสูตร (แยกจากขั้นตอน)
/// คนที่ยังไม่ซื้อสูตร official ได้แค่ชื่อจาก backend จึงแสดงแค่ชื่อ + บอกว่าซื้อแล้วจะเห็นปริมาณ
class FoodIngredients extends StatelessWidget {
  const FoodIngredients({
    super.key,
    required this.ingredients,
    required this.amountsLocked,
  });

  final List<RecipeIngredientLine> ingredients;

  /// true = ยังไม่ได้ซื้อ (ไม่มีปริมาณ/หมายเหตุให้แสดง)
  final bool amountsLocked;

  @override
  Widget build(BuildContext context) {
    if (ingredients.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              context.l10n.ingredients,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Text(
              context.l10n.itemCount(ingredients.length),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8F1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF6E3CF)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                for (final (index, item) in ingredients.indexed) ...[
                  if (index > 0)
                    Divider(
                      height: 1,
                      color: Colors.brown.withValues(alpha: 0.08),
                    ),
                  _IngredientLine(item: item),
                ],
              ],
            ),
          ),
        ),
        if (amountsLocked) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  context.l10n.ingredientAmountsLocked,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _IngredientLine extends StatelessWidget {
  const _IngredientLine({required this.item});

  final RecipeIngredientLine item;

  @override
  Widget build(BuildContext context) {
    final amount = item.amountLabel;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    text: item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    children: [
                      if (item.isOptional)
                        TextSpan(
                          text: '  (${context.l10n.ingredientOptional})',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                if (item.note != null)
                  Text(
                    item.note!,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
              ],
            ),
          ),
          if (amount.isNotEmpty) ...[
            const SizedBox(width: 12),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFFB4532A),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
