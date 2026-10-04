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
