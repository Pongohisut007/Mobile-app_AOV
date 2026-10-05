import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter_application_1/bloc/cart/cart_bloc.dart';
import 'package:flutter_application_1/bloc/cart/cart_event.dart';
import 'package:flutter_application_1/bloc/favorite/favorite_bloc.dart';
import 'package:flutter_application_1/bloc/favorite/favorite_event.dart';
import 'package:flutter_application_1/bloc/purchased_recipes/purchased_recipes_bloc.dart';
import 'package:flutter_application_1/bloc/purchased_recipes/purchased_recipes_event.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/repositories/cart_repository.dart';
import 'package:flutter_application_1/repositories/favorite_repository.dart';
import 'package:flutter_application_1/repositories/recipe_library_repository.dart';
import 'package:flutter_application_1/routes/app_routes.dart';
import 'package:flutter_application_1/routes/route_generator.dart';
import 'package:flutter_application_1/widgets/common/app_snack_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ตะกร้ากับหัวใจถูกใช้ข้ามหน้า (home, community, cart, profile)
    // และ CartPage ถูก push เป็น route ใหม่ จึงต้องวาง provider ไว้เหนือ MaterialApp
    // ทั้งสอง bloc อ่าน token จาก secure storage เอง ไม่ต้องส่ง userId ให้
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              CartBloc(HttpCartRepository(baseUrl: ApiConfig.apiBaseUrl))
                ..add(const CartRequested()),
        ),
        BlocProvider(
          create: (_) => FavoriteBloc(
            HttpFavoriteRepository(baseUrl: ApiConfig.apiBaseUrl),
          )..add(const FavoritesRequested()),
        ),
        // โหลดสูตรที่ซื้อแล้วครั้งเดียว หน้า detail/สูตรที่ซื้อแล้วอ่านจากที่นี่
        BlocProvider(
          create: (_) => PurchasedRecipesBloc(
            HttpRecipeLibraryRepository(baseUrl: ApiConfig.apiBaseUrl),
          )..add(const PurchasedRecipesRequested()),
        ),
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          snackBarTheme: appSnackBarTheme,
          // เปลี่ยนหน้าแบบ iOS ทุกแพลตฟอร์ม: เลื่อนเข้าจากขวา ปัดขอบซ้ายเพื่อย้อนกลับได้
          pageTransitionsTheme: PageTransitionsTheme(
            builders: {
              for (final platform in TargetPlatform.values)
                platform: const CupertinoPageTransitionsBuilder(),
            },
          ),
        ),
        initialRoute: AppRoutes.home,
        onGenerateRoute: (settings) => RoutesGenerator.generateRoute(settings),
      ),
    );
  }
}
