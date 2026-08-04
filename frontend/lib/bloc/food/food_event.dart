abstract class FoodEvent {
  FoodEvent();
}

class FetchFoodEvent extends FoodEvent {
  FetchFoodEvent();
}

class FetchFoodByCategoryEvent extends FoodEvent {
  final String category;
  FetchFoodByCategoryEvent(this.category);
}