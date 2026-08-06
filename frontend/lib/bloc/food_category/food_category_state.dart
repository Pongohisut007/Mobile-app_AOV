import 'package:flutter_application_1/models/food_category.dart';

abstract class FoodCategoryState {
  FoodCategoryState();
}

class FoodCategoryInitial extends FoodCategoryState {
  //Constructor
  FoodCategoryInitial();
}

class FoodCategoryLoading extends FoodCategoryState {
  //Constructor
  FoodCategoryLoading();
}

class FoodCategoryLoaded extends FoodCategoryState {
  final List<FoodCategory> categories;
  FoodCategoryLoaded(this.categories);
}

class FoodCategoryError extends FoodCategoryState {
  final String message;
  FoodCategoryError({required this.message});
}