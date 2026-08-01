import 'package:flutter_application_1/models/product.dart';

abstract class ProductState {
  ProductState();
}

class ProductInitial extends ProductState {
  //Constructor
  ProductInitial();
}

class ProductLoading extends ProductState {
  //Constructor
  ProductLoading();
}

class ProductLoaded extends ProductState {
  final List<Product> products;
  ProductLoaded(this.products);
}

class ProductError extends ProductState {
  final String message;
  ProductError({required this.message});
}
