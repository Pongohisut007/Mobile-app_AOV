import 'package:flutter/material.dart';
import 'package:flutter_application_1/routes/app_routes.dart';

import 'package:flutter_bloc/flutter_bloc.dart';import 'package:flutter_application_1/bloc/product/product_bloc.dart';
import 'package:flutter_application_1/bloc/product/product_event.dart';
import 'package:flutter_application_1/bloc/product/product_state.dart';
import 'package:flutter_application_1/widgets/product_card.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(FetchProductEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            "Our Products",
            style: Theme.of(context).textTheme.headlineMedium,
          ), // Text
          Expanded(
            child: BlocBuilder<ProductBloc, ProductState>(
              builder: (context, state) {
                // handle initial state
                if (state is ProductInitial) {
                  return const Center(child: Text("Initial Loading..."));
                }
                // handle loading state 
                if (state is ProductLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                // handle loaded state
                if (state is ProductLoaded) {
                  return ListView.builder(
                    itemCount: state.products.length,
                    itemBuilder: (context, index) {
                      final product = state.products[index];
                      return ProductCard(
                        product: product,
                        onTap: () {
                          // Handle product card tap
                          Navigator.pushNamed(
                            context, 
                            AppRoutes.productDetails,
                            arguments: product.id,
                          );
                        },
                      );
                    },
                  );
                }
                // handle error state
                if (state is ProductError) {
                  return Center(child: Text(state.message));
                }
                // return empty widget
                return const SizedBox.shrink();
              },
            ), // BlocBuilder
          ), // Expanded
        ],
      ), // Column
    ); // Container
  }
}
