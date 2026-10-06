import 'dart:async';
import 'dart:convert';

// foundation ก็ export ชื่อ Category (annotation) มาด้วย เลยต้อง hide ไว้
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/models/category.dart';
import 'package:flutter_application_1/l10n/l10n.dart';
import 'package:flutter_application_1/data/api_cache.dart';
import 'package:flutter_application_1/repositories/app_http_client.dart';

class CategoryRepository {
  static const String baseUrl = ApiConfig.apiBaseUrl;

  // หมวดหมู่แทบไม่เปลี่ยน เก็บใน RAM ไว้ทั้งแอป
  // (หน้าแก้ไข/สร้างสูตรเรียกทุกครั้งที่เปิด จะได้ไม่ต้องรอ API)
  static List<Category>? _cache;

  Future<List<Category>> fetchCategories({bool forceRefresh = false}) async {
    final cached = _cache;
    if (cached != null && !forceRefresh) return cached;

    final categories = await _fetchCategories();
    _cache = categories;
    return categories;
  }

  static const _cacheKey = 'categories';

  /// หมวดชุดล่าสุดที่เคยโหลด (RAM หรือ disk) ไว้แสดงทันทีตอนเปิดแอป ไม่มี = null
  Future<List<Category>?> cachedCategories() async {
    final cached = _cache;
    if (cached != null) return cached;
    final body = await ApiCache.instance.read(_cacheKey);
    if (body == null) return null;
    try {
      return _decode(body);
    } on Object {
      return null;
    }
  }

  // หมวดที่ปิดใช้งาน backend ส่งมาให้เฉพาะ admin (ไว้จัดการ) ในแอปไม่ต้องแสดง
  static List<Category> _decode(String body) {
    final List<dynamic> jsonList = json.decode(body);
    return jsonList
        .map((json) => Category.fromJson(json))
        .where((category) => category.isActive)
        .toList();
  }

  Future<List<Category>> _fetchCategories() async {
    final url = '$baseUrl/categories';
    final response = await appHttpClient.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final body = utf8.decode(response.bodyBytes);
      final categories = _decode(body);
      unawaited(ApiCache.instance.write(_cacheKey, body));
      return categories;
    } else {
      debugPrint('Failed to load categories: ${response.statusCode}');
      throw Exception(appL10n.loadCategoriesFailed);
    }
  }
}
