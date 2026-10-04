sealed class RecipeLibraryEvent {
  const RecipeLibraryEvent();
}

final class RecipeLibraryRequested extends RecipeLibraryEvent {
  const RecipeLibraryRequested();
}

final class RecipeLibraryRefreshRequested extends RecipeLibraryEvent {
  const RecipeLibraryRefreshRequested();
}

/// โหลดหน้าถัดไป (เลื่อนใกล้ล่างสุด)
final class RecipeLibraryMoreRequested extends RecipeLibraryEvent {
  const RecipeLibraryMoreRequested();
}

/// สูตรถูกลบแล้ว (เช่นลบจากหน้ารายละเอียด) เอาออกจากรายการทันทีไม่ต้องรอ API
final class RecipeLibraryItemRemoved extends RecipeLibraryEvent {
  const RecipeLibraryItemRemoved(this.recipeId);

  final String recipeId;
}
