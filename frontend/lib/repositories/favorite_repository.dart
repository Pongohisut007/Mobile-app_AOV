import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_application_1/l10n/l10n.dart';

/// จัดการหัวใจบนการ์ดอาหาร ผูกกับตาราง favorites
/// backend อ่านว่าเป็นรายการโปรดของใครจาก accessToken ไม่ได้รับ userId ทาง query
abstract interface class FavoriteRepository {
  /// id ของสูตรที่คนที่ล็อกอินอยู่กดหัวใจไว้ทั้งหมด
  Future<Set<String>> fetchFavoriteRecipeIds(String accessToken);

  Future<void> addFavorite(String accessToken, String recipeId);

  Future<void> removeFavorite(String accessToken, String recipeId);
}

class HttpFavoriteRepository implements FavoriteRepository {
  HttpFavoriteRepository({
    required String baseUrl,
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 10),
  }) : _baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), ''),
       _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;
  final Duration requestTimeout;

  @override
  Future<Set<String>> fetchFavoriteRecipeIds(String accessToken) async {
    final decoded = await _send(
      () => _client.get(
        Uri.parse('$_baseUrl/favorites'),
        headers: _headers(accessToken),
      ),
      appL10n.actionLoadFavorites,
    );

    if (decoded is! List) {
      throw FavoriteException(appL10n.errorInvalidResponse);
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map((favorite) => favorite['recipeId'])
        .whereType<String>()
        .toSet();
  }

  @override
  Future<void> addFavorite(String accessToken, String recipeId) {
    return _send(
      () => _client.post(
        Uri.parse('$_baseUrl/favorites'),
        headers: _headers(accessToken),
        body: jsonEncode({'recipeId': recipeId}),
      ),
      appL10n.actionSaveRecipe,
    );
  }

  @override
  Future<void> removeFavorite(String accessToken, String recipeId) {
    // ลบด้วย recipeId ตรง ๆ แอปจึงไม่ต้องจำ favoriteId
    final uri = Uri.parse(
      '$_baseUrl/favorites',
    ).replace(queryParameters: {'recipeId': recipeId});

    return _send(
      () => _client.delete(uri, headers: _headers(accessToken)),
      appL10n.actionUnsaveRecipe,
    );
  }

  Map<String, String> _headers(String accessToken) {
    final token = accessToken.trim();
    if (token.isEmpty) {
      throw FavoriteException(appL10n.favoriteSignInRequired);
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
        throw FavoriteException(appL10n.sessionExpired);
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FavoriteException(
          appL10n.errorActionFailed(action, response.statusCode),
        );
      }
      if (response.bodyBytes.isEmpty) return null;

      return jsonDecode(utf8.decode(response.bodyBytes));
    } on TimeoutException {
      throw FavoriteException(appL10n.errorTimeout);
    } on FormatException {
      throw FavoriteException(appL10n.errorInvalidResponse);
    } on http.ClientException catch (error) {
      throw FavoriteException(appL10n.errorConnection(error.message));
    }
  }
}

class FavoriteException implements Exception {
  const FavoriteException(this.message);

  final String message;

  @override
  String toString() => message;
}
