import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/recipe_comment/recipe_comment_bloc.dart';
import 'package:flutter_application_1/bloc/recipe_comment/recipe_comment_event.dart';
import 'package:flutter_application_1/models/recipe_comment.dart';
import 'package:flutter_application_1/repositories/recipe_comment_repository.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_application_1/widgets/recipe_comment/recipe_comment_section.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('closing the edit dialog with cancel does not throw', (
    tester,
  ) async {
    await _pumpCommentSection(tester);
    await _openEditDialog(tester);

    await tester.tap(find.text('ยกเลิก'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('saving the edit dialog does not throw', (tester) async {
    await _pumpCommentSection(tester);
    await _openEditDialog(tester);

    await tester.enterText(find.byType(TextField), 'Updated comment');
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();

    expect(find.text('Updated comment'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpCommentSection(WidgetTester tester) async {
  await tester.pumpWidget(
    BlocProvider(
      create: (_) => RecipeCommentBloc(
        _FakeRecipeCommentRepository(),
        recipeId: 'recipe-id',
        tokenStorage: _FakeTokenStorage(),
      )..add(const RecipeCommentsRequested()),
      child: const MaterialApp(
        home: Scaffold(body: RecipeCommentSection()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openEditDialog(WidgetTester tester) async {
  await tester.tap(find.byTooltip('จัดการความคิดเห็น'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('แก้ไข'));
  await tester.pumpAndSettle();
}

class _FakeTokenStorage extends TokenStorage {
  @override
  Future<String?> readAccessToken() async => 'access-token';

  @override
  Future<String?> readUserId() async => 'owner-id';
}

class _FakeRecipeCommentRepository implements RecipeCommentRepository {
  static const _comment = RecipeComment(
    id: 'comment-id',
    comment: 'Original comment',
    createdAt: null,
    userName: 'Owner',
    userId: 'owner-id',
  );

  @override
  Future<RecipeCommentPage> fetchComments(
    String recipeId, {
    int page = 1,
    int limit = 3,
  }) async {
    return RecipeCommentPage(
      items: const [_comment],
      total: 1,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<RecipeCommentPermission> fetchPermission(
    String accessToken,
    String recipeId,
  ) async {
    return const RecipeCommentPermission(canComment: false);
  }

  @override
  Future<RecipeComment> addComment(
    String accessToken,
    String recipeId,
    String comment,
  ) async => _comment.copyWith(comment: comment);

  @override
  Future<RecipeComment> updateComment(
    String accessToken,
    String recipeId,
    String commentId,
    String comment,
  ) async => _comment.copyWith(comment: comment);

  @override
  Future<void> deleteComment(
    String accessToken,
    String recipeId,
    String commentId,
  ) async {}
}
