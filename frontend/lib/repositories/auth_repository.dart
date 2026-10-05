import 'dart:async';
import 'dart:convert';

import 'package:flutter_application_1/models/auth_response.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/l10n/l10n.dart';

abstract interface class AuthRepository {
  Future<AuthResponse> login({required String email, required String password});

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String displayName,
  });

  /// เข้าสู่ระบบ/สมัครด้วย ID token จาก Google Sign-In
  Future<AuthResponse> loginWithGoogle({required String idToken});

  /// เปลี่ยนรหัสผ่านของคนที่ login อยู่ (ต้องยืนยันรหัสเดิม)
  /// ยังไม่เคยมีรหัสผ่าน (สมัครผ่าน Google) ไม่ต้องส่ง currentPassword = ตั้งรหัสผ่านครั้งแรก
  /// เครื่องอื่นหลุดทันที เครื่องนี้ได้ token ใบใหม่กลับมา ต้องบันทึกแทนใบเดิม
  Future<AuthResponse> changePassword({
    required String accessToken,
    String? currentPassword,
    required String newPassword,
  });

  /// ทำให้ token ทุกใบของบัญชีนี้ใช้ไม่ได้ (รวมเครื่องนี้)
  Future<void> logoutAll({required String accessToken});

  /// ทำให้ token ใบนี้ใช้ไม่ได้ (ออกจากระบบเครื่องนี้ เครื่องอื่นยังอยู่)
  Future<void> logout({required String accessToken});

  /// ปิดบัญชีและลบข้อมูลส่วนตัว (ต้องยืนยันรหัสผ่าน ถ้าบัญชีมีรหัสผ่าน)
  Future<void> deleteAccount({required String accessToken, String? password});

  /// ลืมรหัสผ่าน ขั้นที่ 1: ขอรหัส 6 หลักทางอีเมล
  /// สำเร็จเสมอแม้อีเมลนี้ไม่มีบัญชี (backend ไม่บอก กันคนนอกเดาอีเมล)
  Future<void> requestPasswordReset({
    required String email,
    required String language,
  });

  /// ลืมรหัสผ่าน ขั้นที่ 2: รหัสถูก = ตั้งรหัสใหม่และได้ session กลับมาเลย
  Future<AuthResponse> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });
}

class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository({
    required String baseUrl,
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 10),
  }) : _baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), ''),
       _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;
  final Duration requestTimeout;

  @override
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/auth/login'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email.trim(), 'password': password}),
          )
          .timeout(requestTimeout);

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthRepositoryException(_errorMessage(decoded));
      }
      if (decoded is! Map<String, dynamic>) {
        throw AuthRepositoryException(appL10n.errorInvalidResponse);
      }

      return AuthResponse.fromJson(decoded);
    } on AuthRepositoryException {
      rethrow;
    } on TimeoutException {
      throw AuthRepositoryException(appL10n.errorTimeout);
    } on FormatException {
      throw AuthRepositoryException(appL10n.errorInvalidResponse);
    } on http.ClientException catch (error) {
      throw AuthRepositoryException(appL10n.errorConnection(error.message));
    }
  }

  @override
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    return _sendAuthRequest(
      path: '/auth/register',
      body: {
        'email': email.trim(),
        'password': password,
        'displayName': displayName.trim(),
      },
    );
  }

  @override
  Future<AuthResponse> loginWithGoogle({required String idToken}) {
    return _sendAuthRequest(path: '/auth/google', body: {'idToken': idToken});
  }

  @override
  Future<AuthResponse> changePassword({
    required String accessToken,
    String? currentPassword,
    required String newPassword,
  }) async {
    final decoded = await _postWithToken(
      '/auth/change-password',
      accessToken,
      body: {'currentPassword': ?currentPassword, 'newPassword': newPassword},
    );
    if (decoded is! Map<String, dynamic>) {
      throw AuthRepositoryException(appL10n.errorInvalidResponse);
    }
    return AuthResponse.fromJson(decoded);
  }

  @override
  Future<void> logoutAll({required String accessToken}) async {
    await _postWithToken('/auth/logout-all', accessToken);
  }

  @override
  Future<void> logout({required String accessToken}) async {
    await _postWithToken('/auth/logout', accessToken);
  }

  @override
  Future<void> deleteAccount({
    required String accessToken,
    String? password,
  }) async {
    await _postWithToken(
      '/auth/delete-account',
      accessToken,
      body: {'password': ?password},
    );
  }

  @override
  Future<void> requestPasswordReset({
    required String email,
    required String language,
  }) async {
    await _postWithToken(
      '/auth/forgot-password',
      null,
      body: {'email': email.trim(), 'language': language},
    );
  }

  @override
  Future<AuthResponse> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) {
    return _sendAuthRequest(
      path: '/auth/reset-password',
      body: {
        'email': email.trim(),
        'code': code.trim(),
        'newPassword': newPassword,
      },
    );
  }

  /// POST คืน JSON ที่ได้ (204 = null)
  /// accessToken เป็น null = endpoint ที่ไม่ต้อง login (เช่น ลืมรหัสผ่าน)
  Future<Object?> _postWithToken(
    String path,
    String? accessToken, {
    Map<String, String> body = const {},
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: {
              'Content-Type': 'application/json',
              if (accessToken != null)
                'Authorization': 'Bearer ${accessToken.trim()}',
            },
            body: jsonEncode(body),
          )
          .timeout(requestTimeout);

      if (accessToken != null && response.statusCode == 401) {
        throw AuthRepositoryException(appL10n.sessionExpired);
      }
      final decoded = response.bodyBytes.isEmpty
          ? null
          : jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        // backend ส่งข้อความภาษาไทยมา เช่น "รหัสผ่านปัจจุบันไม่ถูกต้อง"
        throw AuthRepositoryException(_errorMessage(decoded ?? const {}));
      }
      return decoded;
    } on AuthRepositoryException {
      rethrow;
    } on TimeoutException {
      throw AuthRepositoryException(appL10n.errorTimeout);
    } on FormatException {
      throw AuthRepositoryException(appL10n.errorInvalidResponse);
    } on http.ClientException catch (error) {
      throw AuthRepositoryException(appL10n.errorConnection(error.message));
    }
  }

  Future<AuthResponse> _sendAuthRequest({
    required String path,
    required Map<String, String> body,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(requestTimeout);

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthRepositoryException(_errorMessage(decoded));
      }
      if (decoded is! Map<String, dynamic>) {
        throw AuthRepositoryException(appL10n.errorInvalidResponse);
      }
      return AuthResponse.fromJson(decoded);
    } on AuthRepositoryException {
      rethrow;
    } on TimeoutException {
      throw AuthRepositoryException(appL10n.errorTimeout);
    } on FormatException {
      throw AuthRepositoryException(appL10n.errorInvalidResponse);
    } on http.ClientException catch (error) {
      throw AuthRepositoryException(appL10n.errorConnection(error.message));
    }
  }

  String _errorMessage(Object decoded) {
    if (decoded is Map<String, dynamic>) {
      final message = decoded['message'];
      if (message is String) return message;
      if (message is List) return message.join('\n');
    }
    return appL10n.loginFailed;
  }
}

class AuthRepositoryException implements Exception {
  const AuthRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
