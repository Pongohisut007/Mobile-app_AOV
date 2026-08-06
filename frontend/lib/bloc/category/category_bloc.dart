import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/bloc/category/category_event.dart';
import 'package:flutter_application_1/bloc/category/category_state.dart';
import 'package:flutter_application_1/repositories/category_repository.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryRepository repository;

  CategoryBloc(this.repository) : super(const CategoryState()) {
    on<FetchCategoriesEvent>(_onFetchCategoriesEvent);
    on<CategorySelectEvent>(_onCategorySelectEvent);
  }

  Future<void> _onFetchCategoriesEvent(
    FetchCategoriesEvent event,
    Emitter<CategoryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final categories = await repository.fetchCategories();
      emit(state.copyWith(categories: categories, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void _onCategorySelectEvent(
    CategorySelectEvent event,
    Emitter<CategoryState> emit,
  ) {
    // กดอันเดิมซ้ำ = ยกเลิกการกรอง
    final selected = state.selectedId == event.id ? '' : event.id;
    emit(state.copyWith(selectedId: selected));
  }
}
