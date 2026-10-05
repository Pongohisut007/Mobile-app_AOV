import 'dart:convert';

import 'package:flutter_application_1/models/recipe_collection_type.dart';
import 'package:flutter_application_1/repositories/recipe_library_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late List<http.Request> sent;
  late HttpRecipeLibraryRepository repository;

  setUp(() {
    sent = [];
    repository = HttpRecipeLibraryRepository(
      baseUrl: 'http://api',
      client: MockClient((request) async {
        sent.add(request);
        final body = request.url.path.endsWith('/recipe-ids')
            ? ['r1', 'r2']
            : {'data': [], 'total': 0, 'page': 1, 'limit': 10, 'totalPages': 0};
        return http.Response(jsonEncode(body), 200);
      }),
    );
  });

  test(
    'purchased recipes come from the signed-in user, not a user id',
    () async {
      final ids = await repository.fetchPurchasedRecipeIds(
        userId: 'u1',
        accessToken: 'jwt',
      );
      await repository.fetchCollectionPage(
        RecipeCollectionType.purchased,
        userId: 'u1',
        accessToken: 'jwt',
      );

      expect(ids, {'r1', 'r2'});
      expect(sent.map((request) => request.url.path), [
        '/recipe-access/me/recipe-ids',
        '/recipe-access/me',
      ]);
      expect(
        sent.every((r) => r.headers['Authorization'] == 'Bearer jwt'),
        isTrue,
      );
      expect(sent.any((r) => r.url.toString().contains('u1')), isFalse);
    },
  );

  test('drafts send the token so the backend can check the owner', () async {
    await repository.fetchCollectionPage(
      RecipeCollectionType.drafts,
      userId: 'u1',
      accessToken: 'jwt',
    );

    final request = sent.single;
    expect(request.url.path, '/recipes');
    expect(request.url.queryParameters['creatorId'], 'u1');
    expect(request.url.queryParameters['status'], 'draft');
    expect(request.headers['Authorization'], 'Bearer jwt');
  });
}
