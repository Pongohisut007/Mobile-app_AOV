import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_application_1/config/app_info.dart';
import 'package:flutter_application_1/l10n/l10n.dart';
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

Future<void> main() async {
  // ไม่ได้ส่ง --dart-define-from-file มา: แจ้งชัด ๆ ดีกว่าไปพังตอนยิง API
  if (ApiConfig.apiBaseUrl.isEmpty) {
    throw StateError(
      'API_BASE_URL is not set. Run with '
      '--dart-define-from-file=config/dev.json (or config/prod.json)',
    );
  }
  WidgetsFlutterBinding.ensureInitialized();
  // ภาษาที่ผู้ใช้เลือกไว้ (หน้าตั้งค่า) ต้องรู้ก่อนวาดหน้าแรก ไม่งั้นจะเห็นไทยแวบหนึ่ง
  await AppLanguage.load();
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
      // เปลี่ยนภาษาในหน้าตั้งค่า = ทั้งแอปเปลี่ยนทันที ไม่ต้องเปิดใหม่
      child: ValueListenableBuilder<Locale>(
        valueListenable: AppLanguage.notifier,
        builder: (context, locale, _) => MaterialApp(
          // ภาษาหลักเป็นไทย ข้อความทั้งหมดอยู่ใน lib/l10n/*.arb
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          onGenerateTitle: (context) => AppInfo.name,
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
          onGenerateRoute: (settings) =>
              RoutesGenerator.generateRoute(settings),
        ),
      ),
    );
  }
}
