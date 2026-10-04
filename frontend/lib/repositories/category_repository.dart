import 'dart:convert';
// foundation ก็ export ชื่อ Category (annotation) มาด้วย เลยต้อง hide ไว้
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_application_1/models/category.dart';
import 'package:http/http.dart' as http;

class CategoryRepository {
  // Base URL for the API
  static const String baseUrl = 'http://10.0.2.2:3000';
  //static const String baseUrl = 'http://localhost:3000';

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

  Future<List<Category>> _fetchCategories() async {
    final url = '$baseUrl/categories';
    debugPrint('Fetching categories from: $url');
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      final categories = jsonList
          .map((json) => Category.fromJson(json))
          .toList();

      debugPrint('Parsed ${categories.length} categories successfully');
      for (var category in categories) {
        debugPrint('  - ${category.slug}: ${category.name}');
      }

      return categories;
    } else {
      debugPrint('Failed to load categories: ${response.statusCode}');
      throw Exception('Failed to load categories');
    }
  }
}
