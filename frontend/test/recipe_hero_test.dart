import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/common/recipe_hero.dart';
import 'package:flutter_test/flutter_test.dart';

/// การ์ดสูง 300 เรียงในหน้าที่เลื่อนได้ จอทดสอบสูง 600 = เห็นแค่ 2 ใบแรก
Widget _cards(String page, List<String> ids) {
  return Scaffold(
    body: ListView(
      children: [
        for (final id in ids)
          SizedBox(
            height: 300,
            child: RecipeHero(
              recipeId: id,
              imageUrl: '',
              borderRadius: RecipeHero.cardRadius,
              child: ColoredBox(
                key: ValueKey('$page-$id'),
                color: Colors.orange,
              ),
            ),
          ),
      ],
    ),
  );
}

void main() {
  testWidgets('only recipes visible on both pages fly when going back', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // หน้า Home: a, b เห็นบนจอ c อยู่ใต้จอ
    await tester.pumpWidget(MaterialApp(home: _cards('home', ['a', 'b', 'c'])));
    await tester.pump();

    // หน้า All Recipes: c, a เห็นบนจอ b อยู่ใต้จอ
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    unawaited(
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => _cards('more', ['c', 'a', 'b']),
        ),
      ),
    );
    await tester.pumpAndSettle();

    navigator.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // a เห็นทั้งสองหน้า = กำลังบิน (ตัวจริงทั้งสองฝั่งถูกซ่อนระหว่างบิน)
    expect(find.byKey(const ValueKey('home-a')), findsNothing);
    expect(find.byKey(const ValueKey('more-a')), findsNothing);
    // b อยู่ใต้จอในหน้า All Recipes / c อยู่ใต้จอในหน้า Home = ไม่บิน
    expect(find.byKey(const ValueKey('home-b')), findsOneWidget);
    expect(find.byKey(const ValueKey('more-c')), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-a')), findsOneWidget);
  });
}
