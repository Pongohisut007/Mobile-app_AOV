import 'dart:async';
import 'dart:convert';

import 'package:flutter_application_1/models/cart_item.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/l10n/l10n.dart';

/// เรียก REST ของตะกร้า: carts เก็บว่าเป็นของใคร, cart_items เก็บว่ามีสูตรอะไรบ้าง
/// backend อ่านว่าเป็นตะกร้าของใครจาก accessToken ไม่ได้รับ userId ทาง query
abstract interface class CartRepository {
  /// คืน cartId ของคนที่ล็อกอินอยู่ ถ้ายังไม่เคยสร้างจะได้ null
  Future<String?> findCartId(String accessToken);

  /// get-or-create เรียกซ้ำได้ ไม่สร้างตะกร้าเพิ่ม
  Future<String> createCart(String accessToken);

  Future<List<CartItem>> fetchItems(String accessToken, String cartId);

  Future<CartItem> addItem(String accessToken, String cartId, String recipeId);

  Future<void> removeItem(String accessToken, String cartId, String itemId);

  Future<void> clearItems(String accessToken, String cartId);
}

class HttpCartRepository implements CartRepository {
  HttpCartRepository({
    required String baseUrl,
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 10),
  }) : _baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), ''),
       _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;
  final Duration requestTimeout;

  @override
  Future<String?> findCartId(String accessToken) async {
    final decoded = await _send(
      () => _client.get(
        Uri.parse('$_baseUrl/carts'),
        headers: _headers(accessToken),
      ),
      appL10n.actionLoadCart,
    );
    if (decoded is! List) {
      throw CartException(appL10n.errorInvalidResponse);
    }
    // ยังไม่เคยกดเพิ่มของ = ยังไม่มีตะกร้า ไม่ถือว่าผิดพลาด
    if (decoded.isEmpty) return null;

    final cart = decoded.first;
    if (cart is! Map<String, dynamic> || cart['id'] is! String) {
      throw CartException(appL10n.errorInvalidResponse);
    }
    return cart['id'] as String;
  }

  @override
  Future<String> createCart(String accessToken) async {
    final decoded = await _send(
      () => _client.post(
        Uri.parse('$_baseUrl/carts'),
        headers: _headers(accessToken),
      ),
      appL10n.actionOpenCart,
    );

    if (decoded is! Map<String, dynamic> || decoded['id'] is! String) {
      throw CartException(appL10n.errorInvalidResponse);
    }
    return decoded['id'] as String;
  }

  @override
  Future<List<CartItem>> fetchItems(String accessToken, String cartId) async {
    final decoded = await _send(
      () => _client.get(
        Uri.parse('$_baseUrl/carts/$cartId/items'),
        headers: _headers(accessToken),
      ),
      appL10n.actionLoadCart,
    );

    if (decoded is! List) {
      throw CartException(appL10n.errorInvalidResponse);
    }

    return decoded
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw CartException(appL10n.errorInvalidResponse);
          }
          return CartItem.fromJson(item, apiBaseUrl: _baseUrl);
        })
        .toList(growable: false);
  }

  @override
  Future<CartItem> addItem(
    String accessToken,
    String cartId,
    String recipeId,
  ) async {
    final decoded = await _send(
      () => _client.post(
        Uri.parse('$_baseUrl/carts/$cartId/items'),
        headers: _headers(accessToken),
        body: jsonEncode({'recipeId': recipeId}),
      ),
      appL10n.actionAddToCart,
    );

    if (decoded is! Map<String, dynamic>) {
      throw CartException(appL10n.errorInvalidResponse);
    }
    return CartItem.fromJson(decoded, apiBaseUrl: _baseUrl);
  }

  @override
  Future<void> removeItem(String accessToken, String cartId, String itemId) {
    return _send(
      () => _client.delete(
        Uri.parse('$_baseUrl/carts/$cartId/items/$itemId'),
        headers: _headers(accessToken),
      ),
      appL10n.actionRemoveFromCart,
    );
  }

  @override
  Future<void> clearItems(String accessToken, String cartId) {
    return _send(
      () => _client.delete(
        Uri.parse('$_baseUrl/carts/$cartId/items'),
        headers: _headers(accessToken),
      ),
      appL10n.actionClearCart,
    );
  }

  Map<String, String> _headers(String accessToken) {
    final token = accessToken.trim();
    if (token.isEmpty) {
      throw CartException(appL10n.cartSignInRequired);
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
        throw CartException(appL10n.sessionExpired);
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CartException(
          appL10n.errorActionFailed(action, response.statusCode),
        );
      }
      // DELETE ตอบ 204 ไม่มี body ให้ decode
      if (response.bodyBytes.isEmpty) return null;

      return jsonDecode(utf8.decode(response.bodyBytes));
    } on TimeoutException {
      throw CartException(appL10n.errorTimeout);
    } on FormatException {
      throw CartException(appL10n.errorInvalidResponse);
    } on http.ClientException catch (error) {
      throw CartException(appL10n.errorConnection(error.message));
    }
  }
}

class CartException implements Exception {
  const CartException(this.message);

  final String message;

  @override
  String toString() => message;
}
