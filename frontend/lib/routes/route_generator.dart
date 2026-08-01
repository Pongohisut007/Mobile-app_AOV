import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/category/category_bloc.dart';
import 'package:flutter_application_1/bloc/counter/counter_bloc.dart';
import 'package:flutter_application_1/bloc/food/food_bloc.dart';
import 'package:flutter_application_1/bloc/page/page_bloc.dart';
import 'package:flutter_application_1/bloc/product/product_bloc.dart';
import 'package:flutter_application_1/bloc/user/user_bloc.dart';
import 'package:flutter_application_1/repositories/food_repository.dart';
import 'package:flutter_application_1/repositories/product_repository.dart';
import 'package:flutter_application_1/repositories/product_users.dart';
import 'package:flutter_application_1/routes/app_routes.dart';
import 'package:flutter_application_1/views/main_tree.dart';
import 'package:flutter_application_1/views/pages/product_detail_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RoutesGenerator {
  static Route<dynamic> generateRoute(RouteSettings setting) {
    switch (setting.name) {
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => MultiBlocProvider(providers:[
          BlocProvider(
            create: (context) => CounterBloc()
            ),
          BlocProvider(
            create: (context) => PageBloc(),
            ),
          BlocProvider(
            create: (context) => CategoryBloc(),
            ),
          BlocProvider(create: (context) => FoodBloc(FoodRepository())),
          BlocProvider(create: (context) => ProductBloc(ProductRepository())),
          BlocProvider(create: (context) => Userbloc(UserRepository())),
        ],
        child: const MainTreeWidget(title: 'Flutter App'),
      ),
        );
      case AppRoutes.productDetails:
        final productId = setting.arguments as int;
        return MaterialPageRoute(
          builder: (_) => ProductDetailPage(productId: productId),
        );
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) {
        return const Scaffold(
          body: Center(
            child: Text('No route defined'),
          ),
        );
      },
    );
  }
}
