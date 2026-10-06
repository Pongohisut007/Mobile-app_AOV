import 'dart:async';
import 'dart:convert';

import 'package:flutter_application_1/models/paged_result.dart';
import 'package:flutter_application_1/models/recipe_collection_type.dart';
import 'package:flutter_application_1/models/recipe_summary.dart';
import 'package:flutter_application_1/l10n/l10n.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/repositories/app_http_client.dart';

abstract interface class RecipeLibraryRepository {
  Future<PagedResult<RecipeSummary>> fetchCollectionPage(
    RecipeCollectionType type, {
    required String userId,
    required String accessToken,
    int page = 1,
  });

  /// id ของสูตรที่ซื้อแล้วทั้งหมด ใช้เช็กว่าซื้อหรือยังทั้งแอป (ไม่โหลดรายละเอียดสูตร)
  Future<Set<String>> fetchPurchasedRecipeIds({
    required String userId,
    required String accessToken,
  });
}

class HttpRecipeLibraryRepository implements RecipeLibraryRepository {
  HttpRecipeLibraryRepository({
    required String baseUrl,
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 10),
  }) : _baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), ''),
       _client = client ?? appHttpClient;

  /// จำนวนสูตรต่อหน้า (backend รับได้สูงสุด 50)
  static const int pageSize = 20;

  final String _baseUrl;
  final http.Client _client;
  final Duration requestTimeout;

  @override
  Future<PagedResult<RecipeSummary>> fetchCollectionPage(
    RecipeCollectionType type, {
    required String userId,
    required String accessToken,
    int page = 1,
  }) async {
    final normalizedUserId = _requireUserId(userId, accessToken);
    final uri = _uriFor(type, normalizedUserId, page);

    final decoded = await _get(
      uri,
      accessToken,
      errorLabel: type.title(appL10n),
    );
    if (decoded is! Map<String, dynamic>) {
      throw RecipeLibraryException(appL10n.errorInvalidResponse);
    }

    try {
      return PagedResult.fromJson(decoded, (item) {
        final recipeJson = switch (type) {
          RecipeCollectionType.favorites ||
          RecipeCollectionType.purchased => item['recipe'],
          _ => item,
        };
        if (recipeJson is! Map<String, dynamic>) {
          throw RecipeLibraryException(appL10n.errorInvalidResponse);
        }
        return RecipeSummary.fromJson(recipeJson, apiBaseUrl: _baseUrl);
      });
    } on FormatException {
      throw RecipeLibraryException(appL10n.errorInvalidResponse);
    }
  }

  @override
  Future<Set<String>> fetchPurchasedRecipeIds({
    required String userId,
    required String accessToken,
  }) async {
    _requireUserId(userId, accessToken);
    // backend รู้ว่าเป็นของใครจาก token
    final uri = Uri.parse('$_baseUrl/recipe-access/me/recipe-ids');

    final decoded = await _get(
      uri,
      accessToken,
      errorLabel: appL10n.purchasedRecipes,
    );
    if (decoded is! List) {
      throw RecipeLibraryException(appL10n.errorInvalidResponse);
    }
    return {
      for (final id in decoded)
        if (id is String) id,
    };
  }

  String _requireUserId(String userId, String accessToken) {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty || accessToken.trim().isEmpty) {
      throw RecipeLibraryException(appL10n.librarySignInRequired);
    }
    return normalizedUserId;
  }

  Future<Object?> _get(
    Uri uri,
    String accessToken, {
    required String errorLabel,
  }) async {
    try {
      final response = await _client
          .get(uri, headers: {'Authorization': 'Bearer ${accessToken.trim()}'})
          .timeout(requestTimeout);

      if (response.statusCode == 401) {
        throw RecipeLibraryException(appL10n.sessionExpired);
      }
      if (response.statusCode != 200) {
        throw RecipeLibraryException(
          appL10n.errorActionFailed(
            appL10n.actionLoadCollection(errorLabel),
            response.statusCode,
          ),
        );
      }

      return jsonDecode(utf8.decode(response.bodyBytes));
    } on TimeoutException {
      throw RecipeLibraryException(appL10n.errorTimeout);
    } on FormatException {
      throw RecipeLibraryException(appL10n.errorInvalidResponse);
    } on http.ClientException catch (error) {
      throw RecipeLibraryException(appL10n.errorConnection(error.message));
    }
  }

  Uri _uriFor(RecipeCollectionType type, String userId, int page) {
    final paging = {'page': '$page', 'limit': '$pageSize'};
    return switch (type) {
      RecipeCollectionType.myRecipes => Uri.parse('$_baseUrl/recipes').replace(
        queryParameters: {
          'creatorId': userId,
          'status': 'published',
          ...paging,
        },
      ),
      RecipeCollectionType.drafts => Uri.parse('$_baseUrl/recipes').replace(
        queryParameters: {'creatorId': userId, 'status': 'draft', ...paging},
      ),
      // /favorites รู้ว่าเป็นของใครจาก token แล้ว ไม่ต้องส่ง userId
      RecipeCollectionType.favorites => Uri.parse(
        '$_baseUrl/favorites',
      ).replace(queryParameters: paging),
      // /recipe-access/me รู้ว่าเป็นของใครจาก token เหมือน /favorites
      RecipeCollectionType.purchased => Uri.parse(
        '$_baseUrl/recipe-access/me',
      ).replace(queryParameters: paging),
    };
  }
}

class RecipeLibraryException implements Exception {
  const RecipeLibraryException(this.message);

  final String message;

  @override
  String toString() => message;
}
