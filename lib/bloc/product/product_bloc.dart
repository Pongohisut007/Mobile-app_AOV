import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/bloc/product/product_event.dart';
import 'package:flutter_application_1/bloc/product/product_state.dart';
import 'package:flutter_application_1/repositories/product_repository.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository repository;

  ProductBloc(this.repository) : super(ProductInitial()) {
    on<FetchProductEvent>(_onFetchProductEvent);
  }

  Future<void> _onFetchProductEvent(
    FetchProductEvent event, 
    Emitter<ProductState> emit) async {
    emit(ProductLoading());
    try {final products = await repository.fetchProducts();
      emit(ProductLoaded(products));
    } catch (e) {
      emit(ProductError(message: e.toString()));
    }
      
  }
}
