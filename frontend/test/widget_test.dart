import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/cart/cart_summary_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('cart checkout button triggers purchase and shows progress', (
    tester,
  ) async {
    var checkoutPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: CartSummaryBar(
            itemCount: 2,
            subtotal: 258,
            onCheckoutPressed: () => checkoutPressed = true,
          ),
        ),
      ),
    );

    expect(find.text('2 items'), findsOneWidget);
    expect(find.text('฿258'), findsOneWidget);
    await tester.tap(find.text('Checkout'));
    expect(checkoutPressed, isTrue);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          bottomNavigationBar: CartSummaryBar(
            itemCount: 2,
            subtotal: 258,
            isCheckingOut: true,
            onCheckoutPressed: null,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Checkout'), findsNothing);
  });
}
