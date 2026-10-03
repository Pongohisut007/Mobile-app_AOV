import 'package:flutter_application_1/models/recipe_summary.dart';

enum PurchasedRecipesStatus { initial, loading, ready, failure }

class PurchasedRecipesState {
  PurchasedRecipesState({
    this.status = PurchasedRecipesStatus.initial,
    this.recipes = const [],
    this.error,
  }) : _recipeIds = {for (final recipe in recipes) recipe.id};

  final PurchasedRecipesStatus status;

  /// สูตรที่ซื้อแล้ว เรียงจากซื้อล่าสุด (ใช้แสดงหน้า "สูตรที่ซื้อแล้ว")
  final List<RecipeSummary> recipes;

  final String? error;

  final Set<String> _recipeIds;

  /// ยังโหลดไม่เสร็จ = ยังไม่รู้ว่าซื้อหรือยัง อย่าเพิ่งตัดสินอะไรบน UI
  bool get isResolved =>
      status == PurchasedRecipesStatus.ready ||
      status == PurchasedRecipesStatus.failure;

  bool isPurchased(String recipeId) => _recipeIds.contains(recipeId);
}
