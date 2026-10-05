import 'dart:async';
import 'dart:convert';

import 'package:flutter_application_1/models/user_profile.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/l10n/l10n.dart';
import 'package:flutter_application_1/data/api_cache.dart';

abstract interface class ProfileRepository {
  Future<UserProfile> fetchProfile(String accessToken);

  /// โปรไฟล์ล่าสุดที่เคยโหลด (ของคนที่ login อยู่) ไม่มี = null
  Future<UserProfile?> cachedProfile();

  /// แก้ชื่อ/รูปโปรไฟล์ของตัวเอง (ไม่ส่ง = ไม่แตะ field นั้น)
  /// avatarPath เป็น path ที่อัปโหลดแล้ว เช่น /uploads/images/xxx.jpg
  Future<UserProfile> updateProfile(
    String accessToken, {
    String? displayName,
    String? avatarPath,
  });
}

class HttpProfileRepository implements ProfileRepository {
  HttpProfileRepository({
    required String baseUrl,
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 10),
  }) : _baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), ''),
       _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;
  final Duration requestTimeout;

  static const _cacheKey = '${ApiCache.userPrefix}profile';

  @override
  Future<UserProfile?> cachedProfile() async {
    final body = await ApiCache.instance.read(_cacheKey);
    if (body == null) return null;
    try {
      return UserProfile.fromJson(
        jsonDecode(body) as Map<String, dynamic>,
        apiBaseUrl: _baseUrl,
      );
    } on Object {
      return null;
    }
  }

  @override
  Future<UserProfile> fetchProfile(String accessToken) {
    return _send(
      accessToken,
      (uri, headers) => _client.get(uri, headers: headers),
      failureLabel: appL10n.actionLoadProfile,
    );
  }

  @override
  Future<UserProfile> updateProfile(
    String accessToken, {
    String? displayName,
    String? avatarPath,
  }) {
    return _send(
      accessToken,
      (uri, headers) => _client.patch(
        uri,
        headers: {...headers, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'displayName': ?displayName,
          'avatarUrl': ?avatarPath,
        }),
      ),
      failureLabel: appL10n.actionSaveProfile,
    );
  }

  Future<UserProfile> _send(
    String accessToken,
    Future<http.Response> Function(Uri uri, Map<String, String> headers)
    request, {
    required String failureLabel,
  }) async {
    final normalizedAccessToken = accessToken.trim();
    if (normalizedAccessToken.isEmpty) {
      throw ProfileRepositoryException(appL10n.signInRequired);
    }
    final uri = Uri.parse('$_baseUrl/auth/profile');

    try {
      final response = await request(uri, {
        'Authorization': 'Bearer $normalizedAccessToken',
      }).timeout(requestTimeout);

      if (response.statusCode != 200) {
        throw ProfileRepositoryException(
          response.statusCode == 401
              ? appL10n.sessionExpired
              : appL10n.errorActionFailed(failureLabel, response.statusCode),
        );
      }

      final body = utf8.decode(response.bodyBytes);
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw ProfileRepositoryException(appL10n.errorInvalidResponse);
      }

      try {
        final profile = UserProfile.fromJson(decoded, apiBaseUrl: _baseUrl);
        // ทั้งโหลดและแก้โปรไฟล์ตอบเป็นโปรไฟล์ล่าสุด เก็บไว้เปิดครั้งหน้า
        unawaited(ApiCache.instance.write(_cacheKey, body));
        return profile;
      } on FormatException catch (error) {
        throw ProfileRepositoryException(error.message);
      }
    } on TimeoutException {
      throw ProfileRepositoryException(appL10n.errorTimeout);
    } on FormatException {
      throw ProfileRepositoryException(appL10n.errorInvalidResponse);
    } on http.ClientException catch (error) {
      throw ProfileRepositoryException(appL10n.errorConnection(error.message));
    }
  }
}

class ProfileRepositoryException implements Exception {
  const ProfileRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
