abstract class FoodCategoryEvent {
  FoodCategoryEvent();
}

class FetchFoodCategoryEvent extends FoodCategoryEvent {
  FetchFoodCategoryEvent();
}

class FetchFoodByCategoryEvent extends FoodCategoryEvent {
  final String category;
  FetchFoodByCategoryEvent(this.category);
}