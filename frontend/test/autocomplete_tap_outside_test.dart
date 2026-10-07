import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/category.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_category_section.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/localized_app.dart';

void main() {
  testWidgets(
    'tapping outside the category search closes it without selecting',
    (tester) async {
      final selected = <Category>[];
      final category = Category.fromJson({
        'id': 'c1',
        'name': 'ยำ',
        'nameEn': 'Salad',
        'slug': 'salad',
      });

      await tester.pumpWidget(
        localizedApp(
          home: Scaffold(
            body: Column(
              children: [
                RecipeCategorySection(
                  categories: [category],
                  selectedCategoryIds: const {},
                  onCategorySelected: selected.add,
                ),
                const SizedBox(key: Key('outside'), height: 200, width: 200),
              ],
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'ย');
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsOneWidget);

      await tester.tap(find.byKey(const Key('outside')));
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '',
      );
      expect(selected, isEmpty);
    },
  );
}
