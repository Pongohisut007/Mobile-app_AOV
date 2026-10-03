import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// รูปที่แนบไปถาม AI
class ChatImage {
  const ChatImage({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;

  /// backend รับเฉพาะ jpeg / png / webp / gif
  MediaType get mediaType {
    final extension = filename.split('.').last.toLowerCase();
    return switch (extension) {
      'png' => MediaType('image', 'png'),
      'webp' => MediaType('image', 'webp'),
      'gif' => MediaType('image', 'gif'),
      _ => MediaType('image', 'jpeg'),
    };
  }
}

/// คุยกับ AI เกี่ยวกับสูตรอาหาร (backend จำบทสนทนาไว้ 20 นาที)
class ChatRepository {
  ChatRepository({
    required String baseUrl,
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 60),
  }) : _baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), ''),
       _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;
  // AI อาจใช้เวลาตอบนาน เลยตั้งไว้นานกว่า API อื่น
  final Duration requestTimeout;

  /// user คนนี้ใช้แชทกับสูตรนี้ได้ไหม (เฉพาะสูตร official ที่ซื้อแล้ว / เป็นเจ้าของ)
  Future<bool> canChat(String accessToken, String recipeId) async {
    final decoded = await _send(
      () => _client.get(
        Uri.parse(
          '$_baseUrl/chat/recipes/${Uri.encodeComponent(recipeId)}/permission',
        ),
        headers: _headers(accessToken),
      ),
    );
    return decoded is Map<String, dynamic> && decoded['canChat'] == true;
  }

  /// ส่งคำถาม (แนบรูปได้) ได้คำตอบของ AI กลับมา
  Future<String> sendMessage(
    String accessToken,
    String recipeId,
    String message, {
    ChatImage? image,
  }) async {
    final text = message.trim();
    final decoded = await _send(() {
      if (image == null) {
        return _client.post(
          Uri.parse('$_baseUrl/chat'),
          headers: _headers(accessToken),
          body: jsonEncode({'recipeId': recipeId, 'message': text}),
        );
      }
      return _sendWithImage(accessToken, recipeId, text, image);
    });
    if (decoded is! Map<String, dynamic> || decoded['message'] is! String) {
      throw const ChatException('AI ตอบกลับมาในรูปแบบที่ไม่ถูกต้อง');
    }
    return decoded['message'] as String;
  }

  /// ล้างบทสนทนาฝั่ง backend เพื่อเริ่มคุยใหม่
  Future<void> reset(String accessToken) async {
    await _send(
      () => _client.delete(
        Uri.parse('$_baseUrl/chat'),
        headers: _headers(accessToken),
      ),
    );
  }

  /// มีรูปต้องส่งเป็น multipart/form-data (รูปอยู่ในฟิลด์ image)
  Future<http.Response> _sendWithImage(
    String accessToken,
    String recipeId,
    String message,
    ChatImage image,
  ) async {
    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/chat'))
      ..headers['Authorization'] = 'Bearer ${accessToken.trim()}'
      ..fields['recipeId'] = recipeId
      ..files.add(
        http.MultipartFile.fromBytes(
          'image',
          image.bytes,
          filename: image.filename,
          contentType: image.mediaType,
        ),
      );
    if (message.isNotEmpty) request.fields['message'] = message;
    return http.Response.fromStream(await _client.send(request));
  }

  Map<String, String> _headers(String accessToken) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${accessToken.trim()}',
  };

  Future<Object?> _send(Future<http.Response> Function() request) async {
    try {
      final response = await request().timeout(requestTimeout);
      if (response.statusCode == 401) {
        throw const ChatException('เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่');
      }
      if (response.statusCode == 403) {
        throw const ChatException('ต้องซื้อสูตรนี้ก่อนจึงจะถาม AI ได้');
      }
      if (response.statusCode == 413) {
        throw const ChatException('รูปใหญ่เกินไป (ไม่เกิน 5MB)');
      }
      if (response.statusCode == 503) {
        throw const ChatException('AI ไม่พร้อมใช้งานชั่วคราว ลองใหม่อีกครั้ง');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ChatException('เกิดข้อผิดพลาด (HTTP ${response.statusCode})');
      }
      if (response.bodyBytes.isEmpty) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on TimeoutException {
      throw const ChatException('AI ตอบช้าเกินไป ลองใหม่อีกครั้ง');
    } on FormatException {
      throw const ChatException('ข้อมูลจาก server ไม่ถูกต้อง');
    } on http.ClientException catch (error) {
      throw ChatException('เชื่อมต่อ server ไม่ได้: ${error.message}');
    }
  }
}

class ChatException implements Exception {
  const ChatException(this.message);

  final String message;

  @override
  String toString() => message;
}
