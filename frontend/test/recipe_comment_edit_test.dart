import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/recipe_comment/recipe_comment_bloc.dart';
import 'package:flutter_application_1/bloc/recipe_comment/recipe_comment_event.dart';
import 'package:flutter_application_1/models/recipe_comment.dart';
import 'package:flutter_application_1/repositories/recipe_comment_repository.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_application_1/widgets/recipe_comment/recipe_comment_section.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/localized_app.dart';

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

  testWidgets('deleting a comment refills the visible page', (tester) async {
    final countUpdates = <int>[];
    final comments = List.generate(
      4,
      (index) => RecipeComment(
        id: 'comment-$index',
        comment: 'Comment ${index + 1}',
        createdAt: null,
        userName: 'Owner',
        userId: 'owner-id',
      ),
    );
    final repository = await _pumpCommentSection(
      tester,
      comments: comments,
      onCommentCountChanged: countUpdates.add,
    );

    expect(find.text('Comment 1'), findsOneWidget);
    expect(find.text('Comment 2'), findsOneWidget);
    expect(find.text('Comment 3'), findsOneWidget);
    expect(find.text('ดูความคิดเห็นเพิ่มเติม'), findsOneWidget);

    await tester.tap(find.byTooltip('จัดการความคิดเห็น').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ลบ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ลบ'));
    await tester.pumpAndSettle();

    expect(find.text('Comment 1'), findsNothing);
    expect(find.text('Comment 2'), findsOneWidget);
    expect(find.text('Comment 3'), findsOneWidget);
    expect(find.text('Comment 4'), findsOneWidget);
    expect(find.text('ดูความคิดเห็นเพิ่มเติม'), findsNothing);
    expect(countUpdates, [3]);
    expect(repository.comments, hasLength(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('creating then immediately deleting uses the latest count', (
    tester,
  ) async {
    final countUpdates = <int>[];
    final initialComments = List.generate(
      3,
      (index) => RecipeComment(
        id: 'comment-$index',
        comment: 'Comment ${index + 1}',
        createdAt: null,
        userName: 'Owner',
        userId: 'owner-id',
      ),
    );
    final repository = await _pumpCommentSection(
      tester,
      comments: initialComments,
      onCommentCountChanged: countUpdates.add,
      canComment: true,
    );

    await tester.enterText(find.byType(TextField), 'New comment');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('ส่งความคิดเห็น'));
    await tester.pumpAndSettle();

    expect(find.text('New comment'), findsOneWidget);
    expect(countUpdates, [4]);
    expect(find.byType(PopupMenuButton<String>), findsNWidgets(3));

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ลบ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ลบ'));
    await tester.pumpAndSettle();

    expect(find.text('New comment'), findsNothing);
    expect(countUpdates, [4, 3]);
    expect(repository.comments, hasLength(3));
    expect(tester.takeException(), isNull);
  });
}

Future<_FakeRecipeCommentRepository> _pumpCommentSection(
  WidgetTester tester, {
  List<RecipeComment>? comments,
  ValueChanged<int>? onCommentCountChanged,
  bool canComment = false,
}) async {
  final repository = _FakeRecipeCommentRepository(
    comments: comments,
    canComment: canComment,
  );
  await tester.pumpWidget(
    BlocProvider(
      create: (_) => RecipeCommentBloc(
        repository,
        recipeId: 'recipe-id',
        tokenStorage: _FakeTokenStorage(),
      )..add(const RecipeCommentsRequested()),
      child: localizedApp(
        home: Scaffold(
          body: RecipeCommentSection(
            onCommentCountChanged: onCommentCountChanged,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
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
  _FakeRecipeCommentRepository({
    List<RecipeComment>? comments,
    this.canComment = false,
  }) : comments = comments ?? [_defaultComment];

  static const _defaultComment = RecipeComment(
    id: 'comment-id',
    comment: 'Original comment',
    createdAt: null,
    userName: 'Owner',
    userId: 'owner-id',
  );

  final List<RecipeComment> comments;
  final bool canComment;

  @override
  Future<RecipeCommentPage> fetchComments(
    String recipeId, {
    int page = 1,
    int limit = 3,
  }) async {
    final start = (page - 1) * limit;
    return RecipeCommentPage(
      items: comments.skip(start).take(limit).toList(growable: false),
      total: comments.length,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<RecipeCommentPermission> fetchPermission(
    String accessToken,
    String recipeId,
  ) async {
    return RecipeCommentPermission(canComment: canComment);
  }

  @override
  Future<RecipeComment> addComment(
    String accessToken,
    String recipeId,
    String comment,
  ) async {
    final created = RecipeComment(
      id: 'new-comment',
      comment: comment,
      createdAt: DateTime.now(),
      userName: 'Owner',
      userId: 'owner-id',
    );
    comments.insert(0, created);
    return created;
  }

  @override
  Future<RecipeComment> updateComment(
    String accessToken,
    String recipeId,
    String commentId,
    String comment,
  ) async {
    final index = comments.indexWhere((item) => item.id == commentId);
    final updated = comments[index].copyWith(comment: comment);
    comments[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteComment(
    String accessToken,
    String recipeId,
    String commentId,
  ) async {
    comments.removeWhere((item) => item.id == commentId);
  }
}
