import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/category/category_bloc.dart';
import 'package:flutter_application_1/bloc/category/category_event.dart';
//import 'package:flutter_application_1/bloc/counter/counter_bloc.dart';
import 'package:flutter_application_1/bloc/food/food_bloc.dart';
import 'package:flutter_application_1/bloc/page/page_bloc.dart';
import 'package:flutter_application_1/bloc/profile/profile_bloc.dart';
import 'package:flutter_application_1/repositories/category_repository.dart';
import 'package:flutter_application_1/bloc/profile/profile_event.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/repositories/food_repository.dart';
import 'package:flutter_application_1/repositories/profile_repository.dart';
import 'package:flutter_application_1/routes/app_routes.dart';
import 'package:flutter_application_1/views/main_tree.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RoutesGenerator {
  static Route<dynamic> generateRoute(RouteSettings setting) {
    switch (setting.name) {
      case AppRoutes.home:
        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
            //BlocProvider(create: (context) => CounterBloc()),
              BlocProvider(create: (context) => PageBloc()),
              BlocProvider(
                create: (context) =>
                    CategoryBloc(CategoryRepository())
                      ..add(FetchCategoriesEvent()),
              ),
              BlocProvider(create: (context) => FoodBloc(FoodRepository())),
              BlocProvider(
                create: (context) => ProfileBloc(
                  HttpProfileRepository(baseUrl: ApiConfig.apiBaseUrl),
                  userId: ApiConfig.profileUserId,
                )..add(const ProfileRequested()),
              ),
            ],
            child: const MainTreeWidget(title: 'Flutter App'),
          ),
        );
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) {
        return const Scaffold(body: Center(child: Text('No route defined')));
      },
    );
  }
}
