import 'dart:async';
import 'dart:convert';

import 'package:flutter_application_1/models/cart_item.dart';
import 'package:flutter_application_1/models/purchase_result.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:http/http.dart' as http;

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
      throw const PurchaseException('กรุณาเข้าสู่ระบบก่อนชำระเงิน');
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
        throw const PurchaseException('เซสชันหมดอายุ กรุณาเข้าสู่ระบบอีกครั้ง');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = _errorMessage(response.bodyBytes);
        throw PurchaseException(
          message ?? 'ชำระเงินจำลองไม่สำเร็จ (HTTP ${response.statusCode})',
        );
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const PurchaseException('Backend ส่งผลการชำระเงินไม่ถูกต้อง');
      }
      return PurchaseResult.fromJson(decoded);
    } on TimeoutException {
      throw const PurchaseException('หมดเวลารอการยืนยันการชำระเงิน');
    } on FormatException {
      throw const PurchaseException('Backend ส่งข้อมูลการชำระเงินไม่ถูกต้อง');
    } on http.ClientException catch (error) {
      throw PurchaseException('เชื่อมต่อ Backend ไม่ได้: ${error.message}');
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
