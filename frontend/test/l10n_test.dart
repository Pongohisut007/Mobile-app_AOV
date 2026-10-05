import 'package:flutter/material.dart';
import 'package:flutter_application_1/l10n/l10n.dart';
import 'package:flutter_application_1/widgets/cart/cart_summary_bar.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/localized_app.dart';

void main() {
  testWidgets('Thai is the default language', (tester) async {
    await tester.pumpWidget(
      localizedApp(
        home: Scaffold(
          bottomNavigationBar: CartSummaryBar(
            itemCount: 1,
            subtotal: 0,
            onCheckoutPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('1 รายการ'), findsOneWidget);
    expect(find.text('ฟรี'), findsOneWidget);
    expect(find.text('ชำระเงิน'), findsOneWidget);
  });

  testWidgets('English is available as a second language', (tester) async {
    await tester.pumpWidget(
      localizedApp(
        locale: AppLanguage.english,
        home: Scaffold(
          bottomNavigationBar: CartSummaryBar(
            itemCount: 2,
            subtotal: 0,
            onCheckoutPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('2 items'), findsOneWidget);
    expect(find.text('Free'), findsOneWidget);
    expect(find.text('Checkout'), findsOneWidget);
  });

  test('English plurals and placeholders', () {
    final en = lookupAppLocalizations(AppLanguage.english);
    expect(en.itemCount(1), '1 item');
    expect(en.timeMinutesAgo(5), '5 minutes ago');
    expect(en.cartAdded('Pad Thai'), 'Added Pad Thai to cart');

    final th = lookupAppLocalizations(AppLanguage.thai);
    expect(th.timeMinutesAgo(5), '5 นาทีที่แล้ว');
    expect(
      th.errorActionFailed(th.actionLoadCart, 500),
      'โหลดตะกร้าไม่สำเร็จ (HTTP 500)',
    );
  });
}
