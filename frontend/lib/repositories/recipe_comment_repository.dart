import 'dart:async';
import 'dart:convert';

import 'package:flutter_application_1/models/recipe_comment.dart';
import 'package:http/http.dart' as http;

class RecipeCommentPermission {
  const RecipeCommentPermission({
    required this.canComment,
    this.userAvatarUrl,
  });

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

  Uri _commentsUri(String recipeId, [String suffix = '']) =>
      Uri.parse(
        '$_baseUrl/recipes/${Uri.encodeComponent(recipeId)}/comments$suffix',
      );

  @override
  Future<RecipeCommentPage> fetchComments(
    String recipeId, {
    int page = 1,
    int limit = 3,
  }) async {
    final uri = _commentsUri(recipeId).replace(
      queryParameters: {'page': '$page', 'limit': '$limit'},
    );
    final decoded = await _send(() => _client.get(uri), 'load comments');
    if (decoded is! Map<String, dynamic>) {
      throw const RecipeCommentException('Backend returned an invalid list.');
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
      'check comment permission',
    );
    if (decoded is! Map<String, dynamic>) {
      throw const RecipeCommentException(
        'Backend returned an invalid comment permission.',
      );
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
      'save comment',
    );
    if (decoded is! Map<String, dynamic>) {
      throw const RecipeCommentException('Backend returned an invalid comment.');
    }
    return RecipeComment.fromJson(decoded);
  }

  Map<String, String> _headers(String accessToken) {
    final token = accessToken.trim();
    if (token.isEmpty) {
      throw const RecipeCommentException('Please sign in to comment.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Object?> _send(
    Future<http.Response> Function() request,
    String action,
  ) async {
    try {
      final response = await request().timeout(requestTimeout);
      if (response.statusCode == 401) {
        throw const RecipeCommentException(
          'Your session has expired. Please sign in again.',
        );
      }
      if (response.statusCode == 403) {
        throw const RecipeCommentException(
          'ต้องซื้อสูตรนี้ก่อนจึงจะแสดงความคิดเห็นได้',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw RecipeCommentException(
          'Could not $action (HTTP ${response.statusCode}).',
        );
      }
      if (response.bodyBytes.isEmpty) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on TimeoutException {
      throw const RecipeCommentException(
        'The request timed out. Check the backend connection.',
      );
    } on FormatException {
      throw const RecipeCommentException('Backend returned malformed JSON.');
    } on http.ClientException catch (error) {
      throw RecipeCommentException(
        'Could not connect to the backend: ${error.message}',
      );
    }
  }
}

class RecipeCommentException implements Exception {
  const RecipeCommentException(this.message);

  final String message;

  @override
  String toString() => message;
}