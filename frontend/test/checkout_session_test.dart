import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/auth/auth_bloc.dart';
import 'package:flutter_application_1/bloc/auth/auth_event.dart';
import 'package:flutter_application_1/bloc/cart/cart_bloc.dart';
import 'package:flutter_application_1/bloc/favorite/favorite_bloc.dart';
import 'package:flutter_application_1/bloc/purchased_recipes/purchased_recipes_bloc.dart';
import 'package:flutter_application_1/models/auth_response.dart';
import 'package:flutter_application_1/models/cart_item.dart';
import 'package:flutter_application_1/repositories/auth_repository.dart';
import 'package:flutter_application_1/repositories/cart_repository.dart';
import 'package:flutter_application_1/repositories/favorite_repository.dart';
import 'package:flutter_application_1/repositories/purchase_repository.dart';
import 'package:flutter_application_1/repositories/recipe_library_repository.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_application_1/views/pages/checkout_failure_page.dart';
import 'package:flutter_application_1/views/pages/login_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'helpers/localized_app.dart';

final _session = AuthResponse.fromJson({
  'accessToken': 'new-jwt',
  'expiresIn': '7d',
  'user': {
    'id': 'u1',
    'email': 'cook@example.com',
    'displayName': 'Cook',
    'role': 'user',
  },
});

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      TokenStorage.accessTokenKey: 'jwt',
      TokenStorage.userIdKey: 'u1',
    });
  });

  group('checkSession before paying', () {
    HttpAuthRepository repositoryReturning(Object statusOrError) =>
        HttpAuthRepository(
          baseUrl: 'http://api',
          client: MockClient((request) async {
            expect(request.url.path, '/auth/me');
            expect(request.headers['Authorization'], 'Bearer jwt');
            if (statusOrError is int) return http.Response('{}', statusOrError);
            throw statusOrError;
          }),
        );

    test('only a 401 means the session is gone', () async {
      expect(
        await repositoryReturning(200).checkSession(accessToken: 'jwt'),
        isTrue,
      );
      expect(
        await repositoryReturning(401).checkSession(accessToken: 'jwt'),
        isFalse,
      );
      // เน็ตหลุด/server ล่ม ไม่ใช่เรื่อง session ให้ขั้นตอนจ่ายเงินแจ้ง error เอง
      expect(
        await repositoryReturning(500).checkSession(accessToken: 'jwt'),
        isTrue,
      );
      expect(
        await repositoryReturning(
          http.ClientException('offline'),
        ).checkSession(accessToken: 'jwt'),
        isTrue,
      );
    });
  });

  test('a 401 while paying is reported as an expired session', () async {
    final repository = HttpMockPurchaseRepository(
      baseUrl: 'http://api',
      client: MockClient((_) async => http.Response('', 401)),
    );
    const item = CartItem(
      id: 'item-1',
      recipeId: 'r1',
      title: 'Soup',
      imageUrl: '',
      price: 59,
    );

    await expectLater(
      repository.purchase(item),
      throwsA(
        isA<PurchaseException>().having(
          (error) => error.sessionExpired,
          'sessionExpired',
          isTrue,
        ),
      ),
    );
  });

  testWidgets('signing in from checkout returns to the cart', (tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final client = MockClient((_) async => http.Response('[]', 200));
    final authBloc = AuthBloc(_FakeAuthRepository());
    bool? result;

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
        child: localizedApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: authBloc,
                      child: const LoginPage(returnOnSuccess: true),
                    ),
                  ),
                );
              },
              child: const Text('cart page'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('cart page'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);

    authBloc.add(AuthSessionStarted(_session));
    await tester.pumpAndSettle();

    // กลับมาหน้าเดิม ไม่ใช่ไปหน้าแรก
    expect(find.byType(LoginPage), findsNothing);
    expect(find.text('cart page'), findsOneWidget);
    expect(result, isTrue);
  });

  testWidgets('the failure page offers to sign in and continue', (
    tester,
  ) async {
    var signIn = false;
    await tester.pumpWidget(
      localizedApp(
        home: Builder(
          builder: (context) => CheckoutFailurePage(
            message: 'เซสชันหมดอายุระหว่างชำระเงิน',
            purchasedCount: 1,
            retryLabel: 'เข้าสู่ระบบเพื่อชำระต่อ',
            retryIcon: Icons.login_rounded,
            onRetry: () => signIn = true,
            onBackToCart: () {},
          ),
        ),
      ),
    );

    expect(find.text('ลองใหม่'), findsNothing);
    expect(find.byIcon(Icons.login_rounded), findsOneWidget);
    await tester.tap(find.text('เข้าสู่ระบบเพื่อชำระต่อ'));
    expect(signIn, isTrue);
  });
}

class _FakeAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
