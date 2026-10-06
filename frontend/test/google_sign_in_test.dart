import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/auth/auth_bloc.dart';
import 'package:flutter_application_1/bloc/auth/auth_event.dart';
import 'package:flutter_application_1/bloc/auth/auth_state.dart';
import 'package:flutter_application_1/models/auth_response.dart';
import 'package:flutter_application_1/models/user_profile.dart';
import 'package:flutter_application_1/repositories/auth_repository.dart';
import 'package:flutter_application_1/repositories/google_sign_in_service.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_application_1/views/pages/change_password_page.dart';
import 'package:flutter_application_1/views/pages/delete_account_page.dart';
import 'package:flutter_application_1/views/pages/login_page.dart';
import 'package:flutter_application_1/widgets/common/auth_style.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/localized_app.dart';

final _response = AuthResponse.fromJson({
  'accessToken': 'jwt',
  'expiresIn': '7d',
  'user': {
    'id': 'u1',
    'email': 'cook@gmail.com',
    'displayName': 'Cook',
    'role': 'user',
  },
});

class _FakeGoogle implements GoogleIdTokenProvider {
  _FakeGoogle(this.result);

  final Future<String?> Function() result;

  @override
  Future<String?> signIn() => result();

  @override
  Future<void> signOut() async {}
}

class _FakeAuthRepository implements AuthRepository {
  String? googleToken;

  @override
  Future<AuthResponse> loginWithGoogle({required String idToken}) async {
    googleToken = idToken;
    return _response;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemoryTokenStorage extends TokenStorage {
  String? savedToken;

  @override
  Future<void> saveSession({
    required String accessToken,
    required String userId,
  }) async {
    savedToken = accessToken;
  }
}

void main() {
  group('AuthBloc Google sign-in', () {
    Future<List<AuthState>> run(
      GoogleIdTokenProvider google,
      _FakeAuthRepository repository,
      _MemoryTokenStorage storage,
    ) async {
      final bloc = AuthBloc(repository, tokenStorage: storage, google: google);
      final states = <AuthState>[];
      final subscription = bloc.stream.listen(states.add);
      bloc.add(const AuthGoogleRequested());
      await Future<void>.delayed(Duration.zero);
      await bloc.close();
      await subscription.cancel();
      return states;
    }

    test('exchanges the Google token for a session', () async {
      final repository = _FakeAuthRepository();
      final storage = _MemoryTokenStorage();
      final states = await run(
        _FakeGoogle(() async => 'google-id-token'),
        repository,
        storage,
      );

      expect(repository.googleToken, 'google-id-token');
      expect(storage.savedToken, 'jwt');
      expect(states.first, isA<AuthLoading>());
      expect(states.last, isA<AuthAuthenticated>());
    });

    test('returns quietly when the user closes the account picker', () async {
      final repository = _FakeAuthRepository();
      final states = await run(
        _FakeGoogle(() async => null),
        repository,
        _MemoryTokenStorage(),
      );

      expect(repository.googleToken, isNull);
      expect(states.last, isA<AuthInitial>());
    });

    test('reports Google errors without the Exception prefix', () async {
      final states = await run(
        _FakeGoogle(() async => throw Exception('Google is down')),
        _FakeAuthRepository(),
        _MemoryTokenStorage(),
      );

      expect(states.last, isA<AuthFailure>());
      expect((states.last as AuthFailure).message, 'Google is down');
    });
  });

  testWidgets('the login page shows a Google button (no Facebook)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      BlocProvider(
        // ไม่ได้ตั้ง GOOGLE_SERVER_CLIENT_ID ตอนเทสต์ = ยังไม่เปิดใช้
        create: (_) => AuthBloc(_FakeAuthRepository()),
        child: localizedApp(home: const LoginPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.facebook), findsNothing);
    await tester.tap(find.text('เข้าสู่ระบบด้วย Google'));
    await tester.pumpAndSettle();

    expect(find.byType(AuthErrorBanner), findsOneWidget);
    expect(find.text('ยังไม่เปิดใช้การเข้าสู่ระบบด้วย Google'), findsOneWidget);
  });

  testWidgets('Google-only accounts set a password without the old one', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedApp(home: const ChangePasswordPage(hasPassword: false)),
    );

    expect(find.text('ตั้งรหัสผ่าน'), findsWidgets);
    expect(find.text('รหัสผ่านปัจจุบัน'), findsNothing);
    expect(find.byType(TextFormField), findsNWidgets(2));

    await tester.pumpWidget(localizedApp(home: const ChangePasswordPage()));
    expect(find.text('รหัสผ่านปัจจุบัน'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));
  });

  testWidgets('Google-only accounts delete by ticking the confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedApp(home: const DeleteAccountPage(hasPassword: false)),
    );
    expect(find.byType(TextFormField), findsNothing);
    expect(find.byType(CheckboxListTile), findsOneWidget);

    await tester.pumpWidget(localizedApp(home: const DeleteAccountPage()));
    expect(find.byType(TextFormField), findsOneWidget);
  });

  test('profiles from older backends count as having a password', () {
    Map<String, dynamic> json(Object? hasPassword) => {
      'id': 'u1',
      'displayName': 'Cook',
      'email': 'cook@gmail.com',
      'role': 'user',
      'status': 'active',
      'recipeCount': 0,
      'purchasedCount': 0,
      'savedCount': 0,
      'draftCount': 0,
      'rating': 0,
      'hasPassword': ?hasPassword,
    };

    expect(
      UserProfile.fromJson(json(null), apiBaseUrl: 'x').hasPassword,
      isTrue,
    );
    expect(
      UserProfile.fromJson(json(false), apiBaseUrl: 'x').hasPassword,
      isFalse,
    );
  });
}
