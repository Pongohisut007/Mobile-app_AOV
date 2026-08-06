import 'package:flutter_application_1/models/category.dart';

class CategoryState {
  final List<Category> categories;
  final String selectedSlug;
  final bool isLoading;
  final String? error;

  const CategoryState({
    this.categories = const [],
    this.selectedSlug = '',
    this.isLoading = false,
    this.error,
  });

  CategoryState copyWith({
    List<Category>? categories,
    String? selectedSlug,
    bool? isLoading,
    String? error,
  }) {
    return CategoryState(
      categories: categories ?? this.categories,
      selectedSlug: selectedSlug ?? this.selectedSlug,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
