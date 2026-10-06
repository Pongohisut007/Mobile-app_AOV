import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/paged_result.dart';
import 'package:flutter_application_1/models/recipe_collection_type.dart';
import 'package:flutter_application_1/models/recipe_summary.dart';
import 'package:flutter_application_1/models/user_profile.dart';
import 'package:flutter_application_1/repositories/recipe_library_repository.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_application_1/widgets/profile/profile_extras.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/localized_app.dart';

UserProfile _profile({
  String role = 'user',
  int recipeCount = 0,
  int draftCount = 0,
}) {
  return UserProfile.fromJson({
    'id': 'u1',
    'displayName': 'Cook',
    'email': 'cook@example.com',
    'role': role,
    'status': 'active',
    'recipeCount': recipeCount,
    'purchasedCount': 0,
    'savedCount': 0,
    'draftCount': draftCount,
    'rating': 0,
  }, apiBaseUrl: 'http://localhost');
}

class _FakeTokenStorage extends TokenStorage {
  @override
  Future<String?> readAccessToken() async => 'token';

  @override
  Future<String?> readUserId() async => 'u1';
}

class _FakeLibraryRepository implements RecipeLibraryRepository {
  _FakeLibraryRepository(this.count, {this.fail = false});

  final int count;
  final bool fail;
  RecipeCollectionType? requested;

  @override
  Future<PagedResult<RecipeSummary>> fetchCollectionPage(
    RecipeCollectionType type, {
    required String userId,
    required String accessToken,
    int page = 1,
  }) async {
    requested = type;
    if (fail) throw Exception('offline');
    return PagedResult(
      items: [
        for (var i = 0; i < count; i++)
          RecipeSummary(
            id: 'r$i',
            title: 'Recipe $i',
            description: '',
            coverImageUrl: null,
            price: 0,
            status: 'published',
            type: 'official',
            categories: const [],
          ),
      ],
      page: 1,
      totalPages: 1,
      total: count,
    );
  }

  @override
  Future<Set<String>> fetchPurchasedRecipeIds({
    required String userId,
    required String accessToken,
  }) async => const {};
}

void main() {
  group('ProfileNudgeCard', () {
    Future<List<String>> pumpCard(
      WidgetTester tester,
      UserProfile profile,
    ) async {
      final taps = <String>[];
      await tester.pumpWidget(
        localizedApp(
          home: Scaffold(
            body: ProfileNudgeCard(
              profile: profile,
              onOpenDrafts: () => taps.add('drafts'),
              onCreateRecipe: () => taps.add('create'),
            ),
          ),
        ),
      );
      return taps;
    }

    testWidgets('drafts come first and open the drafts collection', (
      tester,
    ) async {
      final taps = await pumpCard(tester, _profile(draftCount: 2));
      expect(find.text('เขียนต่อจากที่ค้างไว้'), findsOneWidget);
      expect(find.text('มีฉบับร่าง 2 สูตร'), findsOneWidget);
      await tester.tap(find.byType(ProfileNudgeCard));
      expect(taps, ['drafts']);
    });

    testWidgets('people without recipes are invited to share one', (
      tester,
    ) async {
      final taps = await pumpCard(tester, _profile());
      expect(find.text('แบ่งปันสูตรแรกของคุณ'), findsOneWidget);
      expect(find.text('สร้างสูตรแจกฟรีให้ทุกคนในคอมมูนิตี้'), findsOneWidget);
      await tester.tap(find.byType(ProfileNudgeCard));
      expect(taps, ['create']);

      await pumpCard(tester, _profile(role: 'creator'));
      expect(find.text('สร้างสูตร Official และตั้งราคาขายได้'), findsOneWidget);
    });

    test('nothing to show once recipes are published and no drafts', () {
      expect(ProfileNudgeCard.hasContent(_profile(recipeCount: 3)), isFalse);
      expect(ProfileNudgeCard.hasContent(_profile(recipeCount: 0)), isTrue);
    });
  });

  group('RecentPurchasesSection', () {
    Future<_FakeLibraryRepository> pumpSection(
      WidgetTester tester,
      _FakeLibraryRepository repository, {
      List<String>? opened,
    }) async {
      await tester.pumpWidget(
        localizedApp(
          home: Scaffold(
            body: RecentPurchasesSection(
              repository: repository,
              tokenStorage: _FakeTokenStorage(),
              onOpenRecipe: (recipe) => opened?.add(recipe.id),
              onSeeAll: () => opened?.add('all'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return repository;
    }

    testWidgets('shows at most five recent purchases', (tester) async {
      final opened = <String>[];
      final repository = await pumpSection(
        tester,
        _FakeLibraryRepository(8),
        opened: opened,
      );

      expect(repository.requested, RecipeCollectionType.purchased);
      expect(find.text('ซื้อล่าสุด'), findsOneWidget);
      expect(find.text('Recipe 0'), findsOneWidget);

      await tester.tap(find.text('Recipe 0'));
      await tester.tap(find.text('ดูทั้งหมด'));
      expect(opened, ['r0', 'all']);

      await tester.dragUntilVisible(
        find.text('Recipe 4'),
        find.byType(ListView),
        const Offset(-200, 0),
      );
      expect(find.text('Recipe 4'), findsOneWidget);
      expect(find.text('Recipe 5'), findsNothing);
    });

    testWidgets('hides itself when the list is empty or fails to load', (
      tester,
    ) async {
      await pumpSection(tester, _FakeLibraryRepository(0));
      expect(find.text('ซื้อล่าสุด'), findsNothing);

      await pumpSection(tester, _FakeLibraryRepository(3, fail: true));
      expect(find.text('ซื้อล่าสุด'), findsNothing);
    });
  });
}
