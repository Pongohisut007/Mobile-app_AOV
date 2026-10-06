import 'dart:convert';

import 'package:flutter_application_1/data/api_cache.dart';
import 'package:flutter_application_1/l10n/l10n.dart';
import 'package:flutter_application_1/models/category.dart';
import 'package:flutter_application_1/models/recipe_summary.dart';
import 'package:flutter_application_1/repositories/category_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the English name only when the app is in English', () {
    final category = Category.fromJson({
      'id': 'c1',
      'name': 'อาหารไทย',
      'nameEn': 'Thai food',
      'slug': 'thai-food',
    });

    expect(category.nameFor(AppLanguage.thai), 'อาหารไทย');
    expect(category.nameFor(AppLanguage.english), 'Thai food');
  });

  test('falls back to the Thai name when no English name is set', () {
    for (final nameEn in [null, '', '  ']) {
      final category = Category.fromJson({
        'id': 'c1',
        'name': 'ยำ',
        'nameEn': nameEn,
        'slug': 'spicy-thai-salad',
      });
      expect(category.nameFor(AppLanguage.english), 'ยำ');
    }
  });

  test('search matches either language', () {
    final category = Category.fromJson({
      'id': 'c1',
      'name': 'ก๋วยเตี๋ยว',
      'nameEn': 'Noodles',
      'slug': 'noodles',
    });

    expect(category.matches('noo'), isTrue);
    expect(category.matches('ก๋วย'), isTrue);
    expect(category.matches('rice'), isFalse);
  });

  test('recipe summaries keep both category names', () {
    final recipe = RecipeSummary.fromJson({
      'id': 'r1',
      'title': 'Pad Thai',
      'price': '0',
      'type': 'official',
      'categories': [
        {'id': 'c1', 'name': 'อาหารไทย', 'nameEn': 'Thai food', 'slug': 's'},
      ],
    }, apiBaseUrl: 'http://localhost');

    expect(recipe.categories.single.nameFor(AppLanguage.english), 'Thai food');
    expect(recipe.categories.single.nameFor(AppLanguage.thai), 'อาหารไทย');
  });

  test('the app never lists disabled categories', () async {
    ApiCache.instance = ApiCache(directory: () async => null);
    await ApiCache.instance.write(
      'categories',
      jsonEncode([
        {'id': 'a', 'name': 'ไทย', 'slug': 'thai', 'isActive': true},
        {'id': 'b', 'name': 'เก่า', 'slug': 'old', 'isActive': false},
      ]),
    );

    final categories = await CategoryRepository().cachedCategories();
    expect(categories!.map((category) => category.id), ['a']);
  });
}
