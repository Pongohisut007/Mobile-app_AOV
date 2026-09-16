import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/cart/cart_summary_bar.dart';
import 'package:flutter_application_1/views/pages/checkout_failure_page.dart';
import 'package:flutter_application_1/views/pages/checkout_success_page.dart';
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

  testWidgets('checkout success shows purchase count and actions', (
    tester,
  ) async {
    var viewedRecipes = false;
    var wentHome = false;
    await tester.pumpWidget(
      MaterialApp(
        home: CheckoutSuccessPage(
          purchasedCount: 2,
          onViewRecipes: () => viewedRecipes = true,
          onBackHome: () => wentHome = true,
        ),
      ),
    );

    expect(find.text('เปิดสิทธิ์เข้าถึง 2 สูตรแล้ว'), findsOneWidget);
    await tester.tap(find.text('ดูสูตรที่ซื้อแล้ว'));
    expect(viewedRecipes, isTrue);
    await tester.tap(find.text('กลับหน้าหลัก'));
    expect(wentHome, isTrue);
  });

  testWidgets('checkout failure explains partial purchase and can retry', (
    tester,
  ) async {
    var retried = false;
    var backToCart = false;
    await tester.pumpWidget(
      MaterialApp(
        home: CheckoutFailurePage(
          message: 'ทดสอบชำระไม่สำเร็จ',
          purchasedCount: 1,
          onRetry: () => retried = true,
          onBackToCart: () => backToCart = true,
        ),
      ),
    );

    expect(find.text('ทดสอบชำระไม่สำเร็จ'), findsOneWidget);
    expect(find.textContaining('ซื้อสำเร็จแล้ว 1 สูตร'), findsOneWidget);
    await tester.tap(find.text('ลองใหม่'));
    expect(retried, isTrue);
    await tester.tap(find.text('กลับไปตะกร้า'));
    expect(backToCart, isTrue);
  });
}
