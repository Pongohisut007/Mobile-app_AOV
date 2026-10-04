import 'package:flutter_application_1/models/recipe_summary.dart';

sealed class RecipeLibraryState {
  const RecipeLibraryState();
}

final class RecipeLibraryInitial extends RecipeLibraryState {
  const RecipeLibraryInitial();
}

final class RecipeLibraryLoading extends RecipeLibraryState {
  const RecipeLibraryLoading();
}

final class RecipeLibraryLoaded extends RecipeLibraryState {
  const RecipeLibraryLoaded(
    this.recipes, {
    this.hasMore = false,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  /// สูตรทุกหน้าที่โหลดมาแล้ว
  final List<RecipeSummary> recipes;

  /// backend ยังมีหน้าถัดไป
  final bool hasMore;
  final bool isLoadingMore;

  /// โหลดหน้าถัดไปไม่สำเร็จ (รายการเดิมยังอยู่ ลองใหม่ได้)
  final String? loadMoreError;
}

final class RecipeLibraryFailure extends RecipeLibraryState {
  const RecipeLibraryFailure(this.message);

  final String message;
}
