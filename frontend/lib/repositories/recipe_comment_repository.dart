import 'dart:async';
import 'dart:convert';

import 'package:flutter_application_1/models/recipe_comment.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/l10n/l10n.dart';

class RecipeCommentPermission {
  const RecipeCommentPermission({required this.canComment, this.userAvatarUrl});

  final bool canComment;
  final String? userAvatarUrl;

  factory RecipeCommentPermission.fromJson(Map<String, dynamic> json) {
    return RecipeCommentPermission(
      canComment: json['canComment'] as bool? ?? false,
      userAvatarUrl: json['userAvatarUrl'] as String?,
    );
  }
}

abstract interface class RecipeCommentRepository {
  Future<RecipeCommentPage> fetchComments(
    String recipeId, {
    int page = 1,
    int limit = 3,
  });

  Future<RecipeCommentPermission> fetchPermission(
    String accessToken,
    String recipeId,
  );

  Future<RecipeComment> addComment(
    String accessToken,
    String recipeId,
    String comment,
  );

  Future<RecipeComment> updateComment(
    String accessToken,
    String recipeId,
    String commentId,
    String comment,
  );

  Future<void> deleteComment(
    String accessToken,
    String recipeId,
    String commentId,
  );
}

class HttpRecipeCommentRepository implements RecipeCommentRepository {
  HttpRecipeCommentRepository({
    required String baseUrl,
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 10),
  }) : _baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), ''),
       _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;
  final Duration requestTimeout;

  Uri _commentsUri(String recipeId, [String suffix = '']) => Uri.parse(
    '$_baseUrl/recipes/${Uri.encodeComponent(recipeId)}/comments$suffix',
  );

  Uri _commentUri(String recipeId, String commentId) =>
      _commentsUri(recipeId, '/${Uri.encodeComponent(commentId)}');

  @override
  Future<RecipeCommentPage> fetchComments(
    String recipeId, {
    int page = 1,
    int limit = 3,
  }) async {
    final uri = _commentsUri(
      recipeId,
    ).replace(queryParameters: {'page': '$page', 'limit': '$limit'});
    final decoded = await _send(
      () => _client.get(uri),
      appL10n.actionLoadComments,
    );
    if (decoded is! Map<String, dynamic>) {
      throw RecipeCommentException(appL10n.errorInvalidResponse);
    }
    return RecipeCommentPage.fromJson(decoded);
  }

  @override
  Future<RecipeCommentPermission> fetchPermission(
    String accessToken,
    String recipeId,
  ) async {
    final decoded = await _send(
      () => _client.get(
        _commentsUri(recipeId, '/me'),
        headers: _headers(accessToken),
      ),
      appL10n.actionCheckCommentPermission,
    );
    if (decoded is! Map<String, dynamic>) {
      throw RecipeCommentException(appL10n.errorInvalidResponse);
    }
    return RecipeCommentPermission.fromJson(decoded);
  }

  @override
  Future<RecipeComment> addComment(
    String accessToken,
    String recipeId,
    String comment,
  ) async {
    final decoded = await _send(
      () => _client.post(
        _commentsUri(recipeId),
        headers: _headers(accessToken),
        body: jsonEncode({'comment': comment.trim()}),
      ),
      appL10n.actionSaveComment,
      forbiddenMessage: appL10n.buyToComment,
    );
    if (decoded is! Map<String, dynamic>) {
      throw RecipeCommentException(appL10n.errorInvalidResponse);
    }
    return RecipeComment.fromJson(decoded);
  }

  @override
  Future<RecipeComment> updateComment(
    String accessToken,
    String recipeId,
    String commentId,
    String comment,
  ) async {
    final decoded = await _send(
      () => _client.patch(
        _commentUri(recipeId, commentId),
        headers: _headers(accessToken),
        body: jsonEncode({'comment': comment.trim()}),
      ),
      appL10n.actionUpdateComment,
      forbiddenMessage: appL10n.editOwnCommentOnly,
    );
    if (decoded is! Map<String, dynamic>) {
      throw RecipeCommentException(appL10n.errorInvalidResponse);
    }
    return RecipeComment.fromJson(decoded);
  }

  @override
  Future<void> deleteComment(
    String accessToken,
    String recipeId,
    String commentId,
  ) async {
    await _send(
      () => _client.delete(
        _commentUri(recipeId, commentId),
        headers: _headers(accessToken),
      ),
      appL10n.actionDeleteComment,
      forbiddenMessage: appL10n.deleteOwnCommentOnly,
    );
  }

  Map<String, String> _headers(String accessToken) {
    final token = accessToken.trim();
    if (token.isEmpty) {
      throw RecipeCommentException(appL10n.commentSignInRequired);
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Object?> _send(
    Future<http.Response> Function() request,
    String action, {
    String? forbiddenMessage,
  }) async {
    try {
      final response = await request().timeout(requestTimeout);
      if (response.statusCode == 401) {
        throw RecipeCommentException(appL10n.sessionExpired);
      }
      if (response.statusCode == 403) {
        throw RecipeCommentException(
          forbiddenMessage ?? appL10n.errorNoPermission(action),
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw RecipeCommentException(
          appL10n.errorActionFailed(action, response.statusCode),
        );
      }
      if (response.bodyBytes.isEmpty) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on TimeoutException {
      throw RecipeCommentException(appL10n.errorTimeout);
    } on FormatException {
      throw RecipeCommentException(appL10n.errorInvalidResponse);
    } on http.ClientException catch (error) {
      throw RecipeCommentException(appL10n.errorConnection(error.message));
    }
  }
}

class RecipeCommentException implements Exception {
  const RecipeCommentException(this.message);

  final String message;

  @override
  String toString() => message;
}
