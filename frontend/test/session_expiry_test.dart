import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/cart/cart_bloc.dart';
import 'package:flutter_application_1/bloc/favorite/favorite_bloc.dart';
import 'package:flutter_application_1/bloc/purchased_recipes/purchased_recipes_bloc.dart';
import 'package:flutter_application_1/data/session_expiry.dart';
import 'package:flutter_application_1/repositories/app_http_client.dart';
import 'package:flutter_application_1/repositories/cart_repository.dart';
import 'package:flutter_application_1/repositories/favorite_repository.dart';
import 'package:flutter_application_1/repositories/recipe_library_repository.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_application_1/routes/app_routes.dart';
import 'package:flutter_application_1/widgets/common/session_expiry_listener.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'helpers/localized_app.dart';

void _signedInAs(String token) {
  FlutterSecureStorage.setMockInitialValues({
    TokenStorage.accessTokenKey: token,
    TokenStorage.userIdKey: 'u1',
  });
  TokenStorage.currentUserId.value = 'u1';
}

/// รอให้ SessionExpiry (ที่ client สั่งแบบไม่รอ) ทำงานเสร็จ
Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  group('SessionAwareClient', () {
    SessionAwareClient clientReturning(int status) =>
        SessionAwareClient(MockClient((_) async => http.Response('', status)));

    test('a 401 for the current token signs out on this device', () async {
      _signedInAs('jwt-1');
      final expired = SessionExpiry.events.first;

      await clientReturning(401).get(
        Uri.parse('http://api/carts'),
        headers: {'Authorization': 'Bearer jwt-1'},
      );
      await expired.timeout(const Duration(seconds: 1));

      expect(await TokenStorage().readAccessToken(), isNull);
      expect(TokenStorage.currentUserId.value, isNull);
    });

    test('ignores 401s without a token, like a wrong password', () async {
      _signedInAs('jwt-1');
      await clientReturning(401).post(Uri.parse('http://api/auth/login'));
      await _settle();
      expect(await TokenStorage().readAccessToken(), 'jwt-1');
    });

    test('ignores a late 401 from an older session', () async {
      _signedInAs('jwt-new');
      await clientReturning(401).get(
        Uri.parse('http://api/carts'),
        headers: {'authorization': 'Bearer jwt-old'},
      );
      await _settle();
      expect(await TokenStorage().readAccessToken(), 'jwt-new');
    });

    test('ignores other errors', () async {
      _signedInAs('jwt-1');
      await clientReturning(500).get(
        Uri.parse('http://api/carts'),
        headers: {'Authorization': 'Bearer jwt-1'},
      );
      await _settle();
      expect(await TokenStorage().readAccessToken(), 'jwt-1');
    });

    test('reads bearer tokens case-insensitively', () {
      expect(
        SessionAwareClient.bearerToken({'AUTHORIZATION': 'bearer  abc '}),
        'abc',
      );
      expect(
        SessionAwareClient.bearerToken({'Authorization': 'Basic x'}),
        isNull,
      );
      expect(SessionAwareClient.bearerToken({}), isNull);
    });
  });

  test('many 401s at once are handled once', () async {
    _signedInAs('jwt-1');
    var events = 0;
    final subscription = SessionExpiry.events.listen((_) => events++);

    final results = await Future.wait([
      SessionExpiry.report('jwt-1'),
      SessionExpiry.report('jwt-1'),
      SessionExpiry.report('jwt-1'),
    ]);
    await _settle();
    await subscription.cancel();

    expect(results, everyElement(isTrue));
    expect(events, 1);
  });

  testWidgets('every page gets the same sign-in prompt', (tester) async {
    _signedInAs('jwt-1');
    final client = MockClient((_) async => http.Response('[]', 200));

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => CartBloc(
              HttpCartRepository(baseUrl: 'http://api', client: client),
            ),
          ),
          BlocProvider(
            create: (_) => FavoriteBloc(
              HttpFavoriteRepository(baseUrl: 'http://api', client: client),
            ),
          ),
          BlocProvider(
            create: (_) => PurchasedRecipesBloc(
              HttpRecipeLibraryRepository(
                baseUrl: 'http://api',
                client: client,
              ),
            ),
          ),
        ],
        child: SessionExpiryListener(
          child: MaterialApp(
            navigatorKey: appNavigatorKey,
            scaffoldMessengerKey: appScaffoldMessengerKey,
            localizationsDelegates: localizedApp(
              home: const SizedBox(),
            ).localizationsDelegates,
            supportedLocales: localizedApp(
              home: const SizedBox(),
            ).supportedLocales,
            locale: localizedApp(home: const SizedBox()).locale,
            routes: {
              '/': (_) => const Scaffold(body: Text('some page')),
              AppRoutes.login: (_) => const Scaffold(body: Text('login page')),
            },
          ),
        ),
      ),
    );

    await tester.runAsync(() => SessionExpiry.report('jwt-1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่'), findsOneWidget);
    await tester.tap(find.text('เข้าสู่ระบบ'));
    await tester.pumpAndSettle();
    expect(find.text('login page'), findsOneWidget);
  });
}
