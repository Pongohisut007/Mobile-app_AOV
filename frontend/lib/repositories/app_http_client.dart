import 'dart:async';

import 'package:flutter_application_1/data/session_expiry.dart';
import 'package:http/http.dart' as http;

/// http client ที่ repository ทุกตัวใช้ร่วมกัน
/// คำขอที่แนบ token แล้วได้ 401 → แจ้ง [SessionExpiry] ให้ออกจากระบบในเครื่อง
/// (login รหัสผิดไม่ได้แนบ token จึงไม่โดน)
class SessionAwareClient extends http.BaseClient {
  SessionAwareClient([http.Client? inner]) : _inner = inner ?? http.Client();

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request);
    if (response.statusCode == 401) {
      final token = bearerToken(request.headers);
      if (token != null) unawaited(SessionExpiry.report(token));
    }
    return response;
  }

  static String? bearerToken(Map<String, String> headers) {
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() != 'authorization') continue;
      final value = entry.value.trim();
      if (value.toLowerCase().startsWith('bearer ')) {
        final token = value.substring(7).trim();
        return token.isEmpty ? null : token;
      }
    }
    return null;
  }

  @override
  void close() => _inner.close();
}

/// ใช้ตัวนี้แทน http.Client() / http.get() ตรง ๆ
final http.Client appHttpClient = SessionAwareClient();
