enum PurchasedRecipesStatus { initial, loading, ready, failure }

/// id ของสูตรที่ซื้อแล้วทั้งหมด (ไม่มีรายละเอียดสูตร)
/// หน้า "สูตรที่ซื้อแล้ว" โหลดรายละเอียดเองทีละหน้า
class PurchasedRecipesState {
  const PurchasedRecipesState({
    this.status = PurchasedRecipesStatus.initial,
    this.recipeIds = const {},
    this.error,
  });

  final PurchasedRecipesStatus status;
  final Set<String> recipeIds;
  final String? error;

  /// ยังโหลดไม่เสร็จ = ยังไม่รู้ว่าซื้อหรือยัง อย่าเพิ่งตัดสินอะไรบน UI
  bool get isResolved =>
      status == PurchasedRecipesStatus.ready ||
      status == PurchasedRecipesStatus.failure;

  bool isPurchased(String recipeId) => recipeIds.contains(recipeId);
}
