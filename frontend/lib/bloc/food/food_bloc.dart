import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/bloc/food/food_event.dart';
import 'package:flutter_application_1/bloc/food/food_state.dart';
import 'package:flutter_application_1/repositories/food_repository.dart';

class FoodBloc extends Bloc<FoodEvent, FoodState> {
  final FoodRepository repository;

  FoodBloc(this.repository) : super(FoodInitial()) {
    on<FetchFoodEvent>(_onFetchFoodEvent);
  }

  Future<void> _onFetchFoodEvent(
    FetchFoodEvent event,
    Emitter<FoodState> emit) async {
    emit(FoodLoading());
    try {
      final foods = await repository.fetchFoods();
      emit(FoodLoaded(foods));
    } catch (e) {
      emit(FoodError(message: e.toString()));
    }
  }
}