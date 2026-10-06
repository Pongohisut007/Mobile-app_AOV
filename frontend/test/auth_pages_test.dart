import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/auth/auth_bloc.dart';
import 'package:flutter_application_1/models/auth_response.dart';
import 'package:flutter_application_1/repositories/auth_repository.dart';
import 'package:flutter_application_1/views/pages/login_page.dart';
import 'package:flutter_application_1/views/pages/register_page.dart';
import 'package:flutter_application_1/widgets/common/auth_style.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/localized_app.dart';

/// server ตอบ error ทุกครั้ง (เทสต์แค่ฝั่งหน้าจอ)
class _FailingAuthRepository implements AuthRepository {
  _FailingAuthRepository(this.message);

  final String message;
  int calls = 0;

  @override
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    calls++;
    throw AuthRepositoryException(message);
  }

  @override
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    calls++;
    throw AuthRepositoryException(message);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<_FailingAuthRepository> _pump(
  WidgetTester tester,
  Widget page, {
  String error = 'อีเมลหรือรหัสผ่านไม่ถูกต้อง',
}) async {
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final repository = _FailingAuthRepository(error);
  await tester.pumpWidget(
    BlocProvider(
      create: (_) => AuthBloc(repository),
      child: localizedApp(home: page),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  group('LoginPage', () {
    testWidgets('validates the email format before calling the server', (
      tester,
    ) async {
      final repository = await _pump(tester, const LoginPage());

      await tester.enterText(find.byType(TextFormField).at(0), 'not-an-email');
      await tester.enterText(find.byType(TextFormField).at(1), 'password1');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('กรอกอีเมลให้ถูกต้อง'), findsOneWidget);
      expect(repository.calls, 0);
    });

    testWidgets('shows server errors in the form until the user edits', (
      tester,
    ) async {
      final repository = await _pump(tester, const LoginPage());

      await tester.enterText(find.byType(TextFormField).at(0), 'a@b.co');
      await tester.enterText(find.byType(TextFormField).at(1), 'password1');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(repository.calls, 1);
      expect(find.byType(AuthErrorBanner), findsOneWidget);
      expect(find.text('อีเมลหรือรหัสผ่านไม่ถูกต้อง'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(1), 'password2');
      await tester.pump();
      expect(find.byType(AuthErrorBanner), findsNothing);
    });

    testWidgets('has a language button and no back button as the first page', (
      tester,
    ) async {
      await _pump(tester, const LoginPage());

      expect(find.byType(AuthLanguageButton), findsOneWidget);
      expect(find.text('วันนี้ทำอะไรอร่อยดี'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });
  });

  group('RegisterPage', () {
    Future<void> fillValidForm(WidgetTester tester) async {
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Cook');
      await tester.enterText(fields.at(1), 'cook@example.com');
      await tester.enterText(fields.at(2), 'password1');
      await tester.enterText(fields.at(3), 'password1');
    }

    testWidgets('explains the password rule and enforces the 72 limit', (
      tester,
    ) async {
      final repository = await _pump(tester, const RegisterPage());
      expect(find.text('8-72 ตัวอักษร'), findsOneWidget);

      await fillValidForm(tester);
      final tooLong = 'a' * 73;
      await tester.enterText(find.byType(TextFormField).at(2), tooLong);
      await tester.enterText(find.byType(TextFormField).at(3), tooLong);
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('รหัสผ่านต้องไม่เกิน 72 ตัวอักษร'), findsOneWidget);
      expect(repository.calls, 0);
    });

    testWidgets('asks to accept the terms inside the form', (tester) async {
      final repository = await _pump(tester, const RegisterPage());

      await fillValidForm(tester);
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.byType(AuthErrorBanner), findsOneWidget);
      expect(
        find.text('กรุณายอมรับข้อกำหนดการใช้งานและนโยบายความเป็นส่วนตัว'),
        findsOneWidget,
      );
      expect(repository.calls, 0);

      // ติ๊กยอมรับแล้วแถบ error หายไป
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(find.byType(AuthErrorBanner), findsNothing);
    });

    testWidgets('shows server errors in the form', (tester) async {
      final repository = await _pump(
        tester,
        const RegisterPage(),
        error: 'อีเมลนี้ถูกใช้งานแล้ว',
      );

      await fillValidForm(tester);
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.tap(find.byType(Checkbox));
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(repository.calls, 1);
      expect(find.text('อีเมลนี้ถูกใช้งานแล้ว'), findsOneWidget);
    });
  });
}
