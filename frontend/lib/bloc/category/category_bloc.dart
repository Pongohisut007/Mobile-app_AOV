import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/bloc/category/category_event.dart';
import 'package:flutter_application_1/bloc/category/category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  CategoryBloc() : super(CategoryState(selectedCategory: "")) {
    on<CategorySelectEvent>((event, emit) {
      final selected =
          state.selectedCategory == event.category ? "" : event.category;
      emit(CategoryState(selectedCategory: selected));
    });
  }
}