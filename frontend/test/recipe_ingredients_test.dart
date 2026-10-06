import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/food.dart';
import 'package:flutter_application_1/models/recipe_ingredient.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_ingredients_section.dart';
import 'package:flutter_application_1/widgets/food_detail/food_ingredients.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/localized_app.dart';

Map<String, dynamic> _row(
  int sortOrder,
  String name, {
  String? amount,
  String? unit,
  String? note,
  bool optional = false,
}) => {
  'sortOrder': sortOrder,
  'amount': amount,
  'unit': unit,
  'preparationNote': note,
  'isOptional': optional,
  'ingredient': {'id': 'id-$name', 'name': name},
};

void main() {
  group('RecipeIngredientLine', () {
    test('reads rows from the API in their saved order', () {
      final food = Food.fromJson({
        'id': 'r1',
        'title': 'กะเพรา',
        'recipeIngredients': [
          _row(1, 'น้ำปลา', amount: '1.500', unit: 'ช้อนโต๊ะ'),
          _row(0, 'หมูสับ', amount: '200.000', unit: 'กรัม', note: 'สับหยาบ'),
          _row(2, 'พริก', optional: true),
        ],
      }, apiBaseUrl: 'http://api');

      expect(food.ingredients.map((item) => item.name), [
        'หมูสับ',
        'น้ำปลา',
        'พริก',
      ]);
      expect(food.ingredients[0].amountLabel, '200 กรัม');
      expect(food.ingredients[0].note, 'สับหยาบ');
      expect(food.ingredients[1].amountLabel, '1.5 ช้อนโต๊ะ');
      expect(food.ingredients[2].amountLabel, '');
      expect(food.ingredients[2].isOptional, isTrue);
    });

    test('sends the catalog id when picked, the name when typed', () {
      expect(
        const RecipeIngredientLine(
          ingredientId: 'garlic',
          name: 'กระเทียม',
          amount: 5,
          unit: 'กลีบ',
        ).toPayload(),
        {
          'ingredientId': 'garlic',
          'amount': 5.0,
          'unit': 'กลีบ',
          'note': null,
          'isOptional': false,
        },
      );
      expect(
        const RecipeIngredientLine(name: 'ผงชาไทย').toPayload(),
        containsPair('name', 'ผงชาไทย'),
      );
    });

    test('treats the same name with different spacing as a duplicate', () {
      const line = RecipeIngredientLine(name: 'ใบ  กะเพรา');
      expect(
        line.sameIngredientAs(const RecipeIngredientLine(name: ' ใบ กะเพรา ')),
        isTrue,
      );
      expect(
        line.sameIngredientAs(const RecipeIngredientLine(name: 'โหระพา')),
        isFalse,
      );
    });
  });

  group('FoodIngredients on the recipe page', () {
    testWidgets('buyers see amounts and notes', (tester) async {
      await tester.pumpWidget(
        localizedApp(
          home: const Scaffold(
            body: FoodIngredients(
              amountsLocked: false,
              ingredients: [
                RecipeIngredientLine(
                  name: 'หมูสับ',
                  amount: 200,
                  unit: 'กรัม',
                  note: 'สับหยาบ',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('วัตถุดิบ'), findsOneWidget);
      expect(find.text('200 กรัม'), findsOneWidget);
      expect(find.text('สับหยาบ'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
    });

    testWidgets('people who have not bought see names and a hint', (
      tester,
    ) async {
      await tester.pumpWidget(
        localizedApp(
          home: const Scaffold(
            body: FoodIngredients(
              amountsLocked: true,
              ingredients: [RecipeIngredientLine(name: 'หมูสับ')],
            ),
          ),
        ),
      );

      expect(find.textContaining('หมูสับ'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      expect(
        find.text('ซื้อสูตรเพื่อดูปริมาณและวิธีเตรียมวัตถุดิบ'),
        findsOneWidget,
      );
    });

    testWidgets('shows nothing for recipes without ingredients', (
      tester,
    ) async {
      await tester.pumpWidget(
        localizedApp(
          home: const Scaffold(
            body: FoodIngredients(amountsLocked: false, ingredients: []),
          ),
        ),
      );
      expect(find.text('วัตถุดิบ'), findsNothing);
    });
  });

  group('RecipeIngredientsSection in the recipe form', () {
    Future<List<RecipeIngredientLine>> pumpSection(
      WidgetTester tester, {
      List<RecipeIngredientLine> initial = const [],
    }) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      var current = initial;
      await tester.pumpWidget(
        localizedApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => ListView(
                children: [
                  RecipeIngredientsSection(
                    ingredients: current,
                    catalog: const [
                      IngredientOption(id: 'garlic', name: 'กระเทียม'),
                      IngredientOption(id: 'basil', name: 'ใบกะเพรา'),
                    ],
                    onChanged: (value) => setState(() => current = value),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      return current;
    }

    testWidgets('adds an ingredient picked from the catalog', (tester) async {
      await pumpSection(tester);
      await tester.tap(find.text('เพิ่มวัตถุดิบ'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'กระเ');
      await tester.pumpAndSettle();
      await tester.tap(find.text('กระเทียม').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(1), '5');
      await tester.tap(find.text('กลีบ'));
      await tester.tap(find.text('บันทึก'));
      await tester.pumpAndSettle();

      expect(find.text('กระเทียม'), findsOneWidget);
      expect(find.text('5 กลีบ'), findsOneWidget);
    });

    testWidgets('a typed name is marked as new and duplicates are refused', (
      tester,
    ) async {
      await pumpSection(
        tester,
        initial: const [
          RecipeIngredientLine(ingredientId: 'garlic', name: 'กระเทียม'),
        ],
      );
      await tester.tap(find.text('เพิ่มวัตถุดิบ'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'ผงชาไทย');
      await tester.pump();
      expect(find.text('วัตถุดิบใหม่ จะถูกเพิ่มเข้าคลัง'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, ' กระเทียม ');
      await tester.tap(find.text('บันทึก'));
      await tester.pumpAndSettle();
      expect(find.text('มีวัตถุดิบนี้ในรายการแล้ว'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, 'ผงชาไทย');
      await tester.enterText(find.byType(TextFormField).at(1), '1.23456');
      await tester.tap(find.text('บันทึก'));
      await tester.pumpAndSettle();
      expect(
        find.text('ใส่เป็นตัวเลข ทศนิยมไม่เกิน 3 ตำแหน่ง'),
        findsOneWidget,
      );
    });
  });
}
