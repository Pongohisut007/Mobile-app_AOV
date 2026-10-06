import 'package:flutter_application_1/l10n/l10n.dart';
import 'package:flutter_application_1/models/cart_item.dart';
import 'package:flutter_application_1/models/food.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recipe shows the English title only in English', () {
    final food = Food.fromJson({
      'id': 'r1',
      'title': 'ผัดกะเพราไก่',
      'titleEn': 'Spicy basil chicken',
    }, apiBaseUrl: 'http://localhost');

    expect(food.nameFor(AppLanguage.thai), 'ผัดกะเพราไก่');
    expect(food.nameFor(AppLanguage.english), 'Spicy basil chicken');
  });

  test('recipe without an English title falls back to Thai', () {
    for (final titleEn in [null, '', '   ']) {
      final food = Food.fromJson({
        'id': 'r1',
        'title': 'ยำวุ้นเส้น',
        'titleEn': titleEn,
      }, apiBaseUrl: 'http://localhost');
      expect(food.nameFor(AppLanguage.english), 'ยำวุ้นเส้น');
    }
  });

  test('cart items read the English title from the joined recipe', () {
    final item = CartItem.fromJson({
      'id': 'c1',
      'recipeId': 'r1',
      'recipe': {'title': 'ต้มยำ', 'titleEn': 'Tom yum', 'price': '50.00'},
    }, apiBaseUrl: 'http://localhost');

    expect(item.title, 'ต้มยำ');
    expect(item.titleEn, 'Tom yum');
  });
  test('recipe keeps every category with names in both languages', () {
    final food = Food.fromJson({
      'id': 'r1',
      'title': 'ต้มยำกุ้ง',
      'categories': [
        {'id': 'c1', 'name': 'ต้ม', 'nameEn': 'Soup', 'slug': 'soup'},
        {'id': 'c2', 'name': 'อาหารทะเล', 'slug': 'seafood'},
      ],
    }, apiBaseUrl: 'http://localhost');

    expect(food.categoryIds, ['c1', 'c2']);
    expect(food.categories.map((c) => c.nameFor(AppLanguage.english)), [
      'Soup',
      'อาหารทะเล',
    ]);
    expect(food.category, 'ต้ม');
  });
}
