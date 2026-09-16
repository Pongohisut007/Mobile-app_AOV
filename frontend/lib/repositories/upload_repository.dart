import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:http/http.dart' as http;

enum UploadKind { images, videos }

class UploadedFile {
  const UploadedFile({
    required this.filename,
    required this.url,
    required this.mimeType,
    required this.size,
  });

  final String filename;
  final String url;
  final String mimeType;
  final int size;
}

/// ขอ presigned URL จาก backend, PUT ไฟล์ตรงไป R2, แล้วตรวจไฟล์ที่ backend.
class HttpUploadRepository {
  HttpUploadRepository({
    required String baseUrl,
    TokenStorage? tokenStorage,
    http.Client? client,
  }) : _baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), ''),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _client = client ?? http.Client();

  final String _baseUrl;
  final TokenStorage _tokenStorage;
  final http.Client _client;

  Future<UploadedFile> upload({
    required File file,
    required UploadKind kind,
    required String mimeType,
  }) async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw const UploadException('Please sign in before uploading.');
    }

    final size = await file.length();
    final authHeaders = {
      'Authorization': 'Bearer ${token.trim()}',
      'Content-Type': 'application/json',
    };
    final presignResponse = await _client.post(
      Uri.parse('$_baseUrl/uploads/presign'),
      headers: authHeaders,
      body: jsonEncode({
        'kind': kind.name,
        'mimeType': mimeType,
        'size': size,
      }),
    );
    final presign = _decodeResponse(presignResponse, 'Could not prepare upload');
    final filename = presign['filename'] as String;
    final uploadUrl = presign['uploadUrl'] as String;

    final request = http.StreamedRequest('PUT', Uri.parse(uploadUrl))
      ..headers['Content-Type'] = mimeType
      ..contentLength = size;
    final sending = _client.send(request);
    await request.sink.addStream(file.openRead());
    await request.sink.close();
    final putResponse = await http.Response.fromStream(await sending);
    if (putResponse.statusCode < 200 || putResponse.statusCode >= 300) {
      throw UploadException('R2 upload failed (HTTP ${putResponse.statusCode}).');
    }

    final completeResponse = await _client.post(
      Uri.parse('$_baseUrl/uploads/complete'),
      headers: authHeaders,
      body: jsonEncode({'kind': kind.name, 'filename': filename}),
    );
    final completed = _decodeResponse(
      completeResponse,
      'Could not verify uploaded file',
    );
    return UploadedFile(
      filename: completed['filename'] as String,
      url: '$_baseUrl${completed['url'] as String}',
      mimeType: completed['mimeType'] as String,
      size: completed['size'] as int,
    );
  }

  Map<String, dynamic> _decodeResponse(http.Response response, String message) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw UploadException('$message (HTTP ${response.statusCode}).');
    }
    final value = jsonDecode(utf8.decode(response.bodyBytes));
    if (value is! Map<String, dynamic>) {
      throw UploadException('$message: invalid backend response.');
    }
    return value;
  }
}

class UploadException implements Exception {
  const UploadException(this.message);

  final String message;

  @override
  String toString() => message;
}
