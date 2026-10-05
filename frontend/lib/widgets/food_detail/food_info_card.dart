import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/food.dart';
import 'package:flutter_application_1/widgets/food_detail/food_detail_colors.dart';
import 'package:flutter_application_1/widgets/food_detail/info_item.dart';
import 'package:flutter_application_1/l10n/l10n.dart';

/// กล่องสรุปข้อมูล prep / cook / servings / level
class FoodInfoCard extends StatelessWidget {
  const FoodInfoCard({super.key, required this.food});

  final Food food;

  static String _minutes(AppLocalizations l10n, int? value) =>
      value == null ? '-' : l10n.minutesShort(value);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: FoodDetailColors.softOrange,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          InfoItem(
            value: _minutes(l10n, food.preparationMinutes),
            title: l10n.infoPrep,
          ),
          InfoItem(
            value: _minutes(l10n, food.cookingMinutes),
            title: l10n.infoCook,
          ),
          InfoItem(
            value: food.servingCount?.toString() ?? "-",
            title: l10n.infoServings,
          ),
          InfoItem(
            value: l10n.difficultyLabel(food.difficulty),
            title: l10n.infoLevel,
          ),
        ],
      ),
    );
  }
}
