import 'package:flutter_application_1/models/category.dart';

abstract class CategoryState {
  CategoryState();
}

class CategoryInitial extends CategoryState {
  CategoryInitial();
}

class CategoryLoading extends CategoryState {
  CategoryLoading();
}

class CategoryLoaded extends CategoryState {
  final List<Category> categories;

  final String selectedId;
  CategoryLoaded(this.categories, {this.selectedId = ''});
}

class CategoryError extends CategoryState {
  final String message;
  CategoryError({required this.message});
}