import 'dart:async';
import 'dart:convert';

import 'package:flutter_application_1/models/recipe_review.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/l10n/l10n.dart';

/// ให้คะแนนดาวสูตรอาหาร ผูกกับตาราง reviews
/// ดูคะแนนได้ทุกคน แต่ให้คะแนนต้องล็อกอินและซื้อสูตรแล้ว
/// (backend อ่าน user จาก accessToken)
abstract interface class RecipeReviewRepository {
  Future<RecipeReviewSummary> fetchSummary(String recipeId);

  /// หน้ารีวิวทั้งหมด page เริ่มที่ 1
  Future<RecipeReviewPage> fetchReviewPage(
    String recipeId, {
    int page = 1,
    int limit = 20,
  });

  Future<MyRecipeReview> fetchMyReview(String accessToken, String recipeId);

  /// ให้ครั้งแรกหรือแก้คะแนนเดิมก็ใช้ตัวนี้
  Future<RecipeReview> submitReview(
    String accessToken,
    String recipeId, {
    required int rating,
    String comment = '',
    List<String> tags = const [],
  });
}

class HttpRecipeReviewRepository implements RecipeReviewRepository {
  HttpRecipeReviewRepository({
    required String baseUrl,
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 10),
  }) : _baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), ''),
       _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;
  final Duration requestTimeout;

  Uri _reviewsUri(String recipeId, [String suffix = '']) =>
      Uri.parse('$_baseUrl/recipes/$recipeId/reviews$suffix');

  @override
  Future<RecipeReviewSummary> fetchSummary(String recipeId) async {
    final decoded = await _send(
      () => _client.get(_reviewsUri(recipeId)),
      appL10n.actionLoadReviews,
    );
    if (decoded is! Map<String, dynamic>) return const RecipeReviewSummary();
    return RecipeReviewSummary.fromJson(decoded);
  }

  @override
  Future<RecipeReviewPage> fetchReviewPage(
    String recipeId, {
    int page = 1,
    int limit = 20,
  }) async {
    final uri = _reviewsUri(
      recipeId,
      '/list',
    ).replace(queryParameters: {'page': '$page', 'limit': '$limit'});
    final decoded = await _send(
      () => _client.get(uri),
      appL10n.actionLoadReviews,
    );
    if (decoded is! Map<String, dynamic>) {
      throw RecipeReviewException(appL10n.errorInvalidResponse);
    }
    return RecipeReviewPage.fromJson(decoded);
  }

  @override
  Future<MyRecipeReview> fetchMyReview(
    String accessToken,
    String recipeId,
  ) async {
    final decoded = await _send(
      () => _client.get(
        _reviewsUri(recipeId, '/me'),
        headers: _headers(accessToken),
      ),
      appL10n.actionLoadYourReview,
    );
    if (decoded is! Map<String, dynamic>) {
      return const MyRecipeReview(canReview: false);
    }
    return MyRecipeReview.fromJson(decoded);
  }

  @override
  Future<RecipeReview> submitReview(
    String accessToken,
    String recipeId, {
    required int rating,
    String comment = '',
    List<String> tags = const [],
  }) async {
    final decoded = await _send(
      () => _client.put(
        _reviewsUri(recipeId, '/me'),
        headers: _headers(accessToken),
        body: jsonEncode({
          'rating': rating,
          if (comment.trim().isNotEmpty) 'comment': comment.trim(),
          'tags': tags,
        }),
      ),
      appL10n.actionSaveYourReview,
    );
    if (decoded is! Map<String, dynamic>) {
      throw RecipeReviewException(appL10n.errorInvalidResponse);
    }
    return RecipeReview.fromJson(decoded);
  }

  Map<String, String> _headers(String accessToken) {
    final token = accessToken.trim();
    if (token.isEmpty) {
      throw RecipeReviewException(appL10n.reviewSignInRequired);
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
        throw RecipeReviewException(appL10n.sessionExpired);
      }
      if (response.statusCode == 403) {
        throw RecipeReviewException(appL10n.buyToRate);
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw RecipeReviewException(
          appL10n.errorActionFailed(action, response.statusCode),
        );
      }
      if (response.bodyBytes.isEmpty) return null;

      return jsonDecode(utf8.decode(response.bodyBytes));
    } on TimeoutException {
      throw RecipeReviewException(appL10n.errorTimeout);
    } on FormatException {
      throw RecipeReviewException(appL10n.errorInvalidResponse);
    } on http.ClientException catch (error) {
      throw RecipeReviewException(appL10n.errorConnection(error.message));
    }
  }
}

class RecipeReviewException implements Exception {
  const RecipeReviewException(this.message);

  final String message;

  @override
  String toString() => message;
}
