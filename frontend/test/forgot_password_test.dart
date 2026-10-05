import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/auth/auth_bloc.dart';
import 'package:flutter_application_1/bloc/auth/auth_event.dart';
import 'package:flutter_application_1/bloc/auth/auth_state.dart';
import 'package:flutter_application_1/models/auth_response.dart';
import 'package:flutter_application_1/repositories/auth_repository.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_application_1/views/pages/forgot_password_page.dart';
import 'package:flutter_application_1/views/pages/login_page.dart';
import 'package:flutter_application_1/widgets/common/auth_style.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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

class _FakeResetRepository implements AuthRepository {
  final requests = <String>[];
  ({String email, String code, String newPassword})? reset;
  String? resetError;

  @override
  Future<void> requestPasswordReset({
    required String email,
    required String language,
  }) async {
    requests.add('$email/$language');
  }

  @override
  Future<AuthResponse> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    if (resetError case final message?) {
      throw AuthRepositoryException(message);
    }
    reset = (email: email, code: code, newPassword: newPassword);
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

void _tallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// เปิดหน้าลืมรหัสผ่านจากปุ่ม แล้วเก็บค่าที่ pop กลับมา
Future<List<AuthResponse?>> _openPage(
  WidgetTester tester,
  _FakeResetRepository repository,
) async {
  _tallScreen(tester);
  final results = <AuthResponse?>[];
  await tester.pumpWidget(
    localizedApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            results.add(
              await Navigator.of(context).push<AuthResponse>(
                MaterialPageRoute(
                  builder: (_) => ForgotPasswordPage(
                    initialEmail: ' cook@gmail.com ',
                    repository: repository,
                  ),
                ),
              ),
            );
          },
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return results;
}

Future<void> _fillResetForm(
  WidgetTester tester, {
  String code = '123456',
  String password = 'new-pass1',
  String confirm = 'new-pass1',
}) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), code);
  await tester.enterText(fields.at(1), password);
  await tester.enterText(fields.at(2), confirm);
  await tester.tap(find.widgetWithText(AuthPrimaryButton, 'ตั้งรหัสผ่านใหม่'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sends a code, then resets and returns the session', (
    tester,
  ) async {
    final repository = _FakeResetRepository();
    final results = await _openPage(tester, repository);

    // อีเมลจากหน้า login ติดมาให้แล้ว
    expect(find.text('cook@gmail.com'), findsOneWidget);
    await tester.tap(find.text('ส่งรหัสยืนยัน'));
    await tester.pump();

    expect(repository.requests, ['cook@gmail.com/th']);
    expect(find.text('รหัสยืนยัน'), findsOneWidget);
    expect(find.text('ส่งรหัสอีกครั้งได้ใน 60 วินาที'), findsOneWidget);

    await tester.pump(const Duration(seconds: 60));
    expect(find.text('ส่งรหัสอีกครั้ง'), findsOneWidget);

    await _fillResetForm(tester);

    expect(repository.reset?.code, '123456');
    expect(repository.reset?.newPassword, 'new-pass1');
    expect(results.single?.accessToken, 'jwt');
    expect(find.byType(ForgotPasswordPage), findsNothing);
  });

  testWidgets('checks the code and matching passwords before sending', (
    tester,
  ) async {
    final repository = _FakeResetRepository();
    await _openPage(tester, repository);
    await tester.tap(find.text('ส่งรหัสยืนยัน'));
    // รอให้ฟอร์มขั้นที่ 2 สลับเข้ามาจนเสร็จ (ตัวนับถอยหลังทำให้ pumpAndSettle รอนาน)
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await _fillResetForm(tester, code: '12', confirm: 'other-pass');

    expect(find.text('กรอกรหัสตัวเลข 6 หลัก'), findsOneWidget);
    expect(find.text('รหัสผ่านใหม่ไม่ตรงกัน'), findsOneWidget);
    expect(repository.reset, isNull);

    // ปิดหน้าให้ตัวนับถอยหลังหยุด
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('shows server errors and can go back to change the email', (
    tester,
  ) async {
    final repository = _FakeResetRepository()
      ..resetError = 'รหัสยืนยันไม่ถูกต้องหรือหมดอายุแล้ว';
    await _openPage(tester, repository);
    await tester.tap(find.text('ส่งรหัสยืนยัน'));
    // รอให้ฟอร์มขั้นที่ 2 สลับเข้ามาจนเสร็จ (ตัวนับถอยหลังทำให้ pumpAndSettle รอนาน)
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await _fillResetForm(tester);
    expect(find.byType(AuthErrorBanner), findsOneWidget);
    expect(find.byType(ForgotPasswordPage), findsOneWidget);

    await tester.tap(find.text('เปลี่ยนอีเมล'));
    await tester.pumpAndSettle();
    expect(find.text('ส่งรหัสยืนยัน'), findsOneWidget);
    expect(find.byType(AuthErrorBanner), findsNothing);
  });

  testWidgets('rejects an invalid email without calling the server', (
    tester,
  ) async {
    final repository = _FakeResetRepository();
    await _openPage(tester, repository);
    await tester.enterText(find.byType(TextFormField), 'not-an-email');
    await tester.tap(find.text('ส่งรหัสยืนยัน'));
    await tester.pump();

    expect(repository.requests, isEmpty);
    expect(find.text('รหัสยืนยัน'), findsNothing);
  });

  testWidgets('the login page opens forgot password', (tester) async {
    _tallScreen(tester);
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => AuthBloc(_FakeResetRepository()),
        child: localizedApp(home: const LoginPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('ลืมรหัสผ่าน?'));
    await tester.pumpAndSettle();
    expect(find.byType(ForgotPasswordPage), findsOneWidget);
  });

  test('AuthSessionStarted saves the session and signs in', () async {
    final storage = _MemoryTokenStorage();
    final bloc = AuthBloc(_FakeResetRepository(), tokenStorage: storage);
    final states = <AuthState>[];
    final subscription = bloc.stream.listen(states.add);

    bloc.add(AuthSessionStarted(_response));
    await Future<void>.delayed(Duration.zero);
    await bloc.close();
    await subscription.cancel();

    expect(storage.savedToken, 'jwt');
    expect(states.single, isA<AuthAuthenticated>());
  });

  group('HttpAuthRepository password reset', () {
    test('requests a code without a token', () async {
      late http.Request sent;
      final repository = HttpAuthRepository(
        baseUrl: 'http://api/',
        client: MockClient((request) async {
          sent = request;
          return http.Response('', 204);
        }),
      );

      await repository.requestPasswordReset(
        email: ' cook@gmail.com ',
        language: 'en',
      );

      expect(sent.url.toString(), 'http://api/auth/forgot-password');
      expect(sent.headers.containsKey('Authorization'), isFalse);
      expect(jsonDecode(sent.body), {
        'email': 'cook@gmail.com',
        'language': 'en',
      });
    });

    test('returns the session after a reset and reports errors', () async {
      var fail = false;
      final repository = HttpAuthRepository(
        baseUrl: 'http://api',
        client: MockClient((request) async {
          expect(request.url.path, '/auth/reset-password');
          if (fail) {
            return http.Response(
              jsonEncode({'message': 'รหัสยืนยันไม่ถูกต้องหรือหมดอายุแล้ว'}),
              400,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          return http.Response(
            jsonEncode({
              'accessToken': 'jwt',
              'expiresIn': '7d',
              'user': {
                'id': 'u1',
                'email': 'cook@gmail.com',
                'displayName': 'Cook',
                'role': 'user',
              },
            }),
            200,
          );
        }),
      );

      final response = await repository.resetPassword(
        email: 'cook@gmail.com',
        code: '123456',
        newPassword: 'new-pass1',
      );
      expect(response.accessToken, 'jwt');

      fail = true;
      await expectLater(
        repository.resetPassword(
          email: 'cook@gmail.com',
          code: '000000',
          newPassword: 'new-pass1',
        ),
        throwsA(
          isA<AuthRepositoryException>().having(
            (error) => error.message,
            'message',
            'รหัสยืนยันไม่ถูกต้องหรือหมดอายุแล้ว',
          ),
        ),
      );
    });
  });
}
