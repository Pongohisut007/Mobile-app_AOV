import 'dart:async';
import 'dart:convert';

import 'package:flutter_application_1/models/banner_rating.dart';
import 'package:http/http.dart' as http;

/// ให้คะแนนดาว event ผูกกับตาราง banner_ratings
/// ดูคะแนนได้ทุกคน แต่ให้คะแนนต้องล็อกอิน (backend อ่าน user จาก accessToken)
abstract interface class BannerRatingRepository {
  Future<BannerRatingSummary> fetchSummary(String bannerId);

  /// คะแนนที่คนที่ล็อกอินอยู่เคยให้ไว้ ยังไม่เคยให้ = null
  Future<BannerRating?> fetchMyRating(String accessToken, String bannerId);

  /// ให้ครั้งแรกหรือแก้คะแนนเดิมก็ใช้ตัวนี้
  Future<BannerRating> rate(
    String accessToken,
    String bannerId, {
    required int rating,
    String comment = '',
  });
}

class HttpBannerRatingRepository implements BannerRatingRepository {
  HttpBannerRatingRepository({
    required String baseUrl,
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 10),
  }) : _baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), ''),
       _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;
  final Duration requestTimeout;

  Uri _ratingsUri(String bannerId, [String suffix = '']) =>
      Uri.parse('$_baseUrl/banners/$bannerId/ratings$suffix');

  @override
  Future<BannerRatingSummary> fetchSummary(String bannerId) async {
    final decoded = await _send(
      () => _client.get(_ratingsUri(bannerId)),
      'load ratings',
    );
    if (decoded is! Map<String, dynamic>) return const BannerRatingSummary();
    return BannerRatingSummary.fromJson(decoded);
  }

  @override
  Future<BannerRating?> fetchMyRating(
    String accessToken,
    String bannerId,
  ) async {
    final decoded = await _send(
      () => _client.get(
        _ratingsUri(bannerId, '/me'),
        headers: _headers(accessToken),
      ),
      'load your rating',
    );
    // backend คืน body ว่างเมื่อยังไม่เคยให้คะแนน
    if (decoded is! Map<String, dynamic>) return null;
    return BannerRating.fromJson(decoded);
  }

  @override
  Future<BannerRating> rate(
    String accessToken,
    String bannerId, {
    required int rating,
    String comment = '',
  }) async {
    final decoded = await _send(
      () => _client.put(
        _ratingsUri(bannerId, '/me'),
        headers: _headers(accessToken),
        body: jsonEncode({
          'rating': rating,
          if (comment.trim().isNotEmpty) 'comment': comment.trim(),
        }),
      ),
      'save your rating',
    );
    if (decoded is! Map<String, dynamic>) {
      throw const BannerRatingException('Backend returned an invalid rating.');
    }
    return BannerRating.fromJson(decoded);
  }

  Map<String, String> _headers(String accessToken) {
    final token = accessToken.trim();
    if (token.isEmpty) {
      throw const BannerRatingException('Please sign in to rate this event.');
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
        throw const BannerRatingException(
          'Your session has expired. Please sign in again.',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw BannerRatingException(
          'Could not $action (HTTP ${response.statusCode}).',
        );
      }
      if (response.bodyBytes.isEmpty) return null;

      return jsonDecode(utf8.decode(response.bodyBytes));
    } on TimeoutException {
      throw const BannerRatingException(
        'The request timed out. Check the backend connection.',
      );
    } on FormatException {
      throw const BannerRatingException('Backend returned malformed JSON.');
    } on http.ClientException catch (error) {
      throw BannerRatingException(
        'Could not connect to the backend: ${error.message}',
      );
    }
  }
}

class BannerRatingException implements Exception {
  const BannerRatingException(this.message);

  final String message;

  @override
  String toString() => message;
}
