import 'package:flutter_application_1/models/food.dart';

abstract class FoodState {
  FoodState();
}

class FoodInitial extends FoodState {
  //Constructor
  FoodInitial();
}

class FoodLoading extends FoodState {
  //Constructor
  FoodLoading();
}

class FoodLoaded extends FoodState {
  final List<Food> foods;
  FoodLoaded(this.foods);
}

class FoodError extends FoodState {
  final String message;
  FoodError({required this.message});
}