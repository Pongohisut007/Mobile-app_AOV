import 'package:flutter/material.dart';
import 'package:flutter_application_1/l10n/l10n.dart';
import 'package:flutter_application_1/views/pages/settings_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// โครงเดียวกับ MaterialApp ใน main.dart: ฟัง AppLanguage.notifier
Widget _app() => ValueListenableBuilder<Locale>(
  valueListenable: AppLanguage.notifier,
  builder: (context, locale, _) => MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: const SettingsPage(),
  ),
);

void main() {
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await AppLanguage.load(storage: const FlutterSecureStorage());
  });

  test('defaults to Thai when nothing was chosen', () {
    expect(AppLanguage.current, AppLanguage.thai);
  });

  test('remembers the chosen language for the next launch', () async {
    await AppLanguage.change(AppLanguage.english);
    // จำลองเปิดแอปใหม่: ค่าในเครื่องยังอยู่ แต่ตัวแปรในหน่วยความจำเริ่มใหม่
    AppLanguage.notifier.value = AppLanguage.thai;
    await AppLanguage.load();
    expect(AppLanguage.current, AppLanguage.english);
  });

  test('unknown stored value falls back to Thai', () async {
    FlutterSecureStorage.setMockInitialValues({'app_language': 'fr'});
    await AppLanguage.load();
    expect(AppLanguage.current, AppLanguage.thai);
  });

  testWidgets('switching language in settings updates the page at once', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    expect(find.text('ตั้งค่า'), findsOneWidget);
    expect(find.text('ไทย'), findsOneWidget);

    await tester.tap(find.text('ภาษา'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(AppLanguage.current, AppLanguage.english);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('ตั้งค่า'), findsNothing);
    // ข้อความที่ไม่มี context (repository/bloc) ก็เปลี่ยนตาม
    expect(appL10n.sessionExpired, startsWith('Your session has expired'));

    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ไทย'));
    await tester.pumpAndSettle();
    expect(find.text('ตั้งค่า'), findsOneWidget);
  });
}
