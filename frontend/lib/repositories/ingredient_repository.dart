import 'dart:async';
import 'dart:convert';

import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/data/api_cache.dart';
import 'package:flutter_application_1/models/recipe_ingredient.dart';
import 'package:flutter_application_1/repositories/app_http_client.dart';
import 'package:http/http.dart' as http;

/// คลังวัตถุดิบ (เปิดใช้งานอยู่) ไว้เป็นตัวเลือกในหน้าสร้าง/แก้สูตร
/// โหลดทั้งหมดครั้งเดียวแล้วกรองในเครื่อง พิมพ์แล้วขึ้นตัวเลือกทันที
class IngredientRepository {
  IngredientRepository({String? baseUrl, http.Client? client})
    : _baseUrl = (baseUrl ?? ApiConfig.apiBaseUrl).replaceAll(
        RegExp(r'/+$'),
        '',
      ),
      _client = client ?? appHttpClient;

  final String _baseUrl;
  final http.Client _client;

  static const _cacheKey = 'ingredients';
  static List<IngredientOption>? _memory;

  /// โหลดไม่ได้ (เช่น ไม่มีเน็ต) = ใช้ที่เคยโหลดไว้ ไม่มีเลย = รายการว่าง
  /// (ยังพิมพ์ชื่อวัตถุดิบใหม่เองได้ ไม่ต้องรอคลัง)
  Future<List<IngredientOption>> fetchAll() async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/ingredients'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final options = _decode(body);
        _memory = options;
        unawaited(ApiCache.instance.write(_cacheKey, body));
        return options;
      }
    } on Exception {
      // ใช้ของเดิมด้านล่าง
    }
    final cached = _memory;
    if (cached != null) return cached;
    final body = await ApiCache.instance.read(_cacheKey);
    return body == null ? const [] : _decode(body);
  }

  static List<IngredientOption> _decode(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! List) return const [];
    return decoded
        .map(IngredientOption.fromJson)
        .whereType<IngredientOption>()
        .toList(growable: false);
  }
}
