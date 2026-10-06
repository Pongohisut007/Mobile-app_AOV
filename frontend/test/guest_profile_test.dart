import 'package:flutter/material.dart';
import 'package:flutter_application_1/l10n/l10n.dart';
import 'package:flutter_application_1/models/user_profile.dart';
import 'package:flutter_application_1/widgets/profile/profile_card.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/localized_app.dart';

void main() {
  Future<void> pumpCard(WidgetTester tester, Locale locale) {
    return tester.pumpWidget(
      localizedApp(
        locale: locale,
        home: Scaffold(
          body: ProfileCard(profile: UserProfile.guest(), onEditPressed: () {}),
        ),
      ),
    );
  }

  testWidgets('the guest name follows the app language', (tester) async {
    await pumpCard(tester, AppLanguage.thai);
    expect(find.text('ผู้เยี่ยมชม'), findsOneWidget);

    // เปลี่ยนภาษาแล้ว profile object เดิม (สร้างไว้ก่อน) ต้องแสดงภาษาใหม่
    await pumpCard(tester, AppLanguage.english);
    expect(find.text('Guest'), findsOneWidget);
    expect(find.text('ผู้เยี่ยมชม'), findsNothing);
  });

  test('signed-in users keep their own name', () {
    final profile = UserProfile.fromJson({
      'id': 'u1',
      'displayName': 'เชฟมุก',
      'email': 'cook@example.com',
      'role': 'creator',
      'status': 'active',
      'recipeCount': 0,
      'purchasedCount': 0,
      'savedCount': 0,
      'draftCount': 0,
      'rating': 0,
    }, apiBaseUrl: 'http://localhost');

    final en = lookupAppLocalizations(AppLanguage.english);
    expect(profile.isGuest, isFalse);
    expect(profile.displayNameFor(en), 'เชฟมุก');
    expect(profile.roleLabel(en), 'Recipe creator');
  });
}
