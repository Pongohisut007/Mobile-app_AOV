import 'package:flutter/material.dart';
import 'package:flutter_application_1/routes/app_routes.dart';
import 'package:flutter_application_1/views/pages/settings_page.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/localized_app.dart';

Widget _settings({required bool isSignedIn, List<String>? openedRoutes}) {
  final app = localizedApp(home: SettingsPage(isSignedIn: isSignedIn));
  return MaterialApp(
    locale: app.locale,
    supportedLocales: app.supportedLocales,
    localizationsDelegates: app.localizationsDelegates,
    home: app.home,
    onGenerateRoute: (settings) {
      openedRoutes?.add(settings.name ?? '');
      return MaterialPageRoute<void>(builder: (_) => const Scaffold());
    },
  );
}

void main() {
  testWidgets('guests see only settings that work without an account', (
    tester,
  ) async {
    final opened = <String>[];
    await tester.pumpWidget(_settings(isSignedIn: false, openedRoutes: opened));

    expect(find.text('ภาษา'), findsOneWidget);
    expect(find.text('ช่วยเหลือและติดต่อ'), findsOneWidget);
    expect(find.text('นโยบายความเป็นส่วนตัว'), findsOneWidget);
    expect(find.text('เกี่ยวกับแอป'), findsOneWidget);

    expect(find.text('บัญชี'), findsNothing);
    expect(find.text('เปลี่ยนรหัสผ่าน'), findsNothing);
    expect(find.text('ออกจากระบบทุกอุปกรณ์'), findsNothing);
    expect(find.text('ออกจากระบบ'), findsNothing);
    expect(find.text('ลบบัญชี'), findsNothing);

    await tester.scrollUntilVisible(find.text('เข้าสู่ระบบ'), 200);
    await tester.tap(find.text('เข้าสู่ระบบ'));
    await tester.pumpAndSettle();
    expect(opened, [AppRoutes.login]);
  });

  testWidgets('signed-in users see every account setting', (tester) async {
    await tester.pumpWidget(_settings(isSignedIn: true));

    expect(find.text('เปลี่ยนรหัสผ่าน'), findsOneWidget);
    expect(find.text('ออกจากระบบทุกอุปกรณ์'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('ลบบัญชี'), 200);
    expect(find.text('ออกจากระบบ'), findsOneWidget);
    expect(find.text('ลบบัญชี'), findsOneWidget);
    expect(find.text('เข้าสู่ระบบ'), findsNothing);
  });
}
