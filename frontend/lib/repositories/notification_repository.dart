import 'dart:async';
import 'dart:convert';

import 'package:flutter_application_1/l10n/l10n.dart';
import 'package:flutter_application_1/models/app_notification.dart';
import 'package:flutter_application_1/models/paged_result.dart';
import 'package:flutter_application_1/repositories/app_http_client.dart';
import 'package:http/http.dart' as http;

/// กล่องแจ้งเตือน + ตั้งค่า push + ลงทะเบียนเครื่องรับ push
/// backend รู้ว่าเป็นของใครจาก accessToken
abstract interface class NotificationRepository {
  Future<PagedResult<AppNotification>> fetchPage(
    String accessToken, {
    required int page,
  });

  Future<int> fetchUnreadCount(String accessToken);

  Future<void> markRead(String accessToken, String id);

  Future<void> markAllRead(String accessToken);

  Future<NotificationSettings> fetchSettings(String accessToken);

  Future<NotificationSettings> updateSettings(
    String accessToken,
    NotificationSettings settings,
  );

  Future<void> registerDevice(
    String accessToken, {
    required String token,
    required String platform,
    required String locale,
  });

  /// ไม่ต้อง login (ใช้ตอนออกจากระบบ/session หมดอายุ)
  Future<void> unregisterDevice(String token);
}

class HttpNotificationRepository implements NotificationRepository {
  HttpNotificationRepository({
    required String baseUrl,
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 10),
  }) : _baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), ''),
       _client = client ?? appHttpClient;

  static const pageSize = 20;

  final String _baseUrl;
  final http.Client _client;
  final Duration requestTimeout;

  @override
  Future<PagedResult<AppNotification>> fetchPage(
    String accessToken, {
    required int page,
  }) async {
    final decoded = await _send(
      () => _client.get(
        Uri.parse(
          '$_baseUrl/notifications',
        ).replace(queryParameters: {'page': '$page', 'limit': '$pageSize'}),
        headers: _headers(accessToken),
      ),
    );
    if (decoded is! Map<String, dynamic>) {
      throw NotificationException(appL10n.errorInvalidResponse);
    }
    return PagedResult.fromJson(
      decoded,
      (json) => AppNotification.fromJson(json, apiBaseUrl: _baseUrl),
    );
  }

  @override
  Future<int> fetchUnreadCount(String accessToken) async {
    final decoded = await _send(
      () => _client.get(
        Uri.parse('$_baseUrl/notifications/unread-count'),
        headers: _headers(accessToken),
      ),
    );
    if (decoded is! Map<String, dynamic>) {
      throw NotificationException(appL10n.errorInvalidResponse);
    }
    return (decoded['count'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<void> markRead(String accessToken, String id) => _send(
    () => _client.patch(
      Uri.parse('$_baseUrl/notifications/$id/read'),
      headers: _headers(accessToken),
    ),
  );

  @override
  Future<void> markAllRead(String accessToken) => _send(
    () => _client.post(
      Uri.parse('$_baseUrl/notifications/read-all'),
      headers: _headers(accessToken),
    ),
  );

  @override
  Future<NotificationSettings> fetchSettings(String accessToken) async {
    final decoded = await _send(
      () => _client.get(
        Uri.parse('$_baseUrl/notifications/settings'),
        headers: _headers(accessToken),
      ),
    );
    if (decoded is! Map<String, dynamic>) {
      throw NotificationException(appL10n.errorInvalidResponse);
    }
    return NotificationSettings.fromJson(decoded);
  }

  @override
  Future<NotificationSettings> updateSettings(
    String accessToken,
    NotificationSettings settings,
  ) async {
    final decoded = await _send(
      () => _client.patch(
        Uri.parse('$_baseUrl/notifications/settings'),
        headers: _headers(accessToken),
        body: jsonEncode(settings.toJson()),
      ),
    );
    if (decoded is! Map<String, dynamic>) {
      throw NotificationException(appL10n.errorInvalidResponse);
    }
    return NotificationSettings.fromJson(decoded);
  }

  @override
  Future<void> registerDevice(
    String accessToken, {
    required String token,
    required String platform,
    required String locale,
  }) => _send(
    () => _client.post(
      Uri.parse('$_baseUrl/notifications/devices'),
      headers: _headers(accessToken),
      body: jsonEncode({
        'token': token,
        'platform': platform,
        'locale': locale,
      }),
    ),
  );

  @override
  Future<void> unregisterDevice(String token) => _send(
    () => _client.delete(
      Uri.parse('$_baseUrl/notifications/devices'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token}),
    ),
  );

  Map<String, String> _headers(String accessToken) {
    final token = accessToken.trim();
    if (token.isEmpty) {
      throw NotificationException(appL10n.notificationsSignInRequired);
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Object?> _send(Future<http.Response> Function() request) async {
    try {
      final response = await request().timeout(requestTimeout);
      if (response.statusCode == 401) {
        throw NotificationException(appL10n.sessionExpired);
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw NotificationException(
          appL10n.errorActionFailed(
            appL10n.actionLoadNotifications,
            response.statusCode,
          ),
        );
      }
      if (response.bodyBytes.isEmpty) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on TimeoutException {
      throw NotificationException(appL10n.errorTimeout);
    } on FormatException {
      throw NotificationException(appL10n.errorInvalidResponse);
    } on http.ClientException catch (error) {
      throw NotificationException(appL10n.errorConnection(error.message));
    }
  }
}

class NotificationException implements Exception {
  const NotificationException(this.message);

  final String message;

  @override
  String toString() => message;
}
