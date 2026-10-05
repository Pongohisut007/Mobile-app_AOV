import 'dart:async';
import 'dart:convert';

import 'package:flutter_application_1/models/cart_item.dart';
import 'package:flutter_application_1/models/purchase_result.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/l10n/l10n.dart';

/// Boundary between the cart UI and a billing provider.
/// Replace HttpMockPurchaseRepository with GooglePlayPurchaseRepository later.
abstract interface class PurchaseRepository {
  Future<PurchaseResult> purchase(CartItem item);
}

class HttpMockPurchaseRepository implements PurchaseRepository {
  HttpMockPurchaseRepository({
    required String baseUrl,
    TokenStorage? tokenStorage,
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 10),
  }) : _baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), ''),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _client = client ?? http.Client();

  final String _baseUrl;
  final TokenStorage _tokenStorage;
  final http.Client _client;
  final Duration requestTimeout;

  @override
  Future<PurchaseResult> purchase(CartItem item) async {
    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken == null || accessToken.trim().isEmpty) {
      throw PurchaseException(appL10n.signInBeforeCheckout);
    }

    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/iap/mock/purchases'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${accessToken.trim()}',
            },
            body: jsonEncode({'cartItemId': item.id}),
          )
          .timeout(requestTimeout);

      if (response.statusCode == 401) {
        throw PurchaseException(appL10n.sessionExpired);
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = _errorMessage(response.bodyBytes);
        throw PurchaseException(
          message ?? appL10n.mockPaymentFailedHttp(response.statusCode),
        );
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw PurchaseException(appL10n.purchaseInvalidResult);
      }
      return PurchaseResult.fromJson(decoded);
    } on TimeoutException {
      throw PurchaseException(appL10n.purchaseTimeout);
    } on FormatException {
      throw PurchaseException(appL10n.errorInvalidResponse);
    } on http.ClientException catch (error) {
      throw PurchaseException(appL10n.errorConnection(error.message));
    }
  }

  String? _errorMessage(List<int> bytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String) return message;
        if (message is List) return message.join(', ');
      }
    } on FormatException {
      return null;
    }
    return null;
  }
}

class PurchaseException implements Exception {
  const PurchaseException(this.message);

  final String message;

  @override
  String toString() => message;
}
