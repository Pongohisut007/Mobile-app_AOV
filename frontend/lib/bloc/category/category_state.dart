import 'package:flutter_application_1/models/category.dart';

class CategoryState {
  final List<Category> categories;
  final String selectedId;
  final bool isLoading;
  final String? error;

  const CategoryState({
    this.categories = const [],
    this.selectedId = '',
    this.isLoading = false,
    this.error,
  });

  CategoryState copyWith({
    List<Category>? categories,
    String? selectedId,
    bool? isLoading,
    String? error,
  }) {
    return CategoryState(
      categories: categories ?? this.categories,
      selectedId: selectedId ?? this.selectedId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
