import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/bloc/food_category/food_category_event.dart';
import 'package:flutter_application_1/bloc/food_category/food_category_state.dart';
import 'package:flutter_application_1/repositories/food_category_repository.dart';

class FoodCategoryBloc extends Bloc<FoodCategoryEvent, FoodCategoryState> {
  final FoodCategoryRepository repository;

  FoodCategoryBloc(this.repository) : super(FoodCategoryInitial()) {
    on<FetchFoodCategoryEvent>(_onFetchFoodCategoriesEvent);
    on<FetchFoodByCategoryEvent>(_onFetchFoodByCategoryEvent);
  }

  Future<void> _onFetchFoodCategoriesEvent(
    FetchFoodCategoryEvent event,
    Emitter<FoodCategoryState> emit) async {
    emit(FoodCategoryLoading());
    try {
      final categories = await repository.fetchFoodCategories();
      emit(FoodCategoryLoaded(categories));
    } catch (e) {
      emit(FoodCategoryError(message: e.toString()));
    }
  }

  Future<void> _onFetchFoodByCategoryEvent(
    FetchFoodByCategoryEvent event,
    Emitter<FoodCategoryState> emit) async {
    emit(FoodCategoryLoading());
    try {
      // ถ้าไม่ได้เลือก category ให้ดึงทั้งหมด กดซ้ำเพื่อยกเลิก
      final categories = event.category.isEmpty
          ? await repository.fetchFoodCategories()
          : await repository.fetchFoodCategoriesByCategory(event.category);
      emit(FoodCategoryLoaded(categories));
    } catch (e) {
      emit(FoodCategoryError(message: e.toString()));
    }
  }
}