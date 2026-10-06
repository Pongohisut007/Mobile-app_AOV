import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/data/api_cache.dart';
import 'package:flutter_application_1/data/recipe_library_cache.dart';
import 'package:flutter_application_1/models/food.dart';
import 'package:flutter_application_1/models/paged_result.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_application_1/l10n/l10n.dart';
import 'package:flutter_application_1/repositories/app_http_client.dart';

class FoodRepository {
  static const String baseUrl = ApiConfig.apiBaseUrl;
  //static const String baseUrl = 'http://localhost:3000';

  /// จำนวนสูตรต่อหน้า (backend รับได้สูงสุด 50)
  static const int pageSize = 20;

  // รายละเอียดสูตรที่เคยเปิดแล้ว เก็บใน RAM เปิดซ้ำจะโชว์ได้ทันทีระหว่างโหลดของใหม่
  // (เก็บเฉพาะผลจาก GET /recipes/:id เพราะรายการสูตรไม่มีขั้นตอน/สิทธิ์ดูสูตรเต็ม)
  static final Map<String, Food> _detailCache = {};

  static Food? cachedFood(String id) => _detailCache[id];

  /// รายละเอียดที่เคยเปิด: RAM ก่อน ไม่มีค่อยอ่านจาก disk (เปิดแอปใหม่ก็ยังมี)
  static Future<Food?> loadCachedFood(String id) async {
    final inMemory = _detailCache[id];
    if (inMemory != null) return inMemory;
    final body = await ApiCache.instance.read(_detailKey(id));
    if (body == null) return null;
    try {
      return _detailCache[id] = _decodeFood(body);
    } on Object {
      return null;
    }
  }

  /// เนื้อหาขึ้นกับว่าใคร login (ซื้อแล้วเห็นขั้นตอนครบ) เปลี่ยนบัญชีต้องล้าง
  /// (ของบน disk ล้างพร้อมข้อมูลผู้ใช้อื่น ๆ ใน clearUserCaches)
  static void clearCache() => _detailCache.clear();

  // ขึ้นกับผู้ชม (ซื้อแล้วเห็นขั้นตอนครบ) จึงเป็นข้อมูลของผู้ใช้
  static String _detailKey(String id) => '${ApiCache.userPrefix}recipe:$id';

  /// หน้าแรกของรายการที่เคยโหลด ใช้แสดงทันทีตอนเปิดแอป/สลับหมวด
  /// (ระหว่างนั้นโหลดของใหม่มาแทน) ไม่เคยโหลด = null
  Future<PagedResult<Food>?> cachedRecipesPage({
    String? type,
    String? status,
    String? categoryId,
    String? sort,
  }) async {
    final uri = _recipesUri(
      type: type,
      status: status,
      categoryId: categoryId,
      sort: sort,
      page: 1,
    );
    final body = await ApiCache.instance.read('list:$uri');
    if (body == null) return null;
    try {
      return _decodePage(body);
    } on Object {
      return null;
    }
  }

  // =========================== เรียกใช้ตรงนี้ ==================================

  /// รายการสูตรทีละหน้า ค่าเริ่มต้นเรียงจากเผยแพร่ล่าสุด
  /// sort: 'rating' = คะแนนรีวิวสูงสุดก่อน (สูตรที่ยังไม่มีรีวิวอยู่ท้าย)
  /// categoryId ว่าง/null = ทุกหมวด
  Future<PagedResult<Food>> fetchRecipesPage({
    String? type,
    String? status,
    String? categoryId,
    String? sort,
    int page = 1,
  }) async {
    final uri = _recipesUri(
      type: type,
      status: status,
      categoryId: categoryId,
      sort: sort,
      page: page,
    );
    return _getFoodsPage(uri, cacheKey: page == 1 ? 'list:$uri' : null);
  }

  static Uri _recipesUri({
    String? type,
    String? status,
    String? categoryId,
    String? sort,
    required int page,
  }) {
    return Uri.parse('$baseUrl/recipes').replace(
      queryParameters: {
        'type': ?type,
        'status': ?status,
        if (categoryId != null && categoryId.isNotEmpty)
          'categoryId': categoryId,
        'sort': ?sort,
        'page': '$page',
        'limit': '$pageSize',
      },
    );
  }

  /// ค้นหาตามชื่อทีละหน้า เรียงตามความใกล้เคียง
  Future<PagedResult<Food>> searchFoods(
    String query, {
    String? type,
    String? categoryId,
    String? status,
    int page = 1,
  }) async {
    final uri = Uri.parse('$baseUrl/recipes/search').replace(
      queryParameters: {
        'q': query,
        'type': ?type,
        'status': ?status,
        'categoryId': ?categoryId,
        'page': '$page',
        'limit': '$pageSize',
      },
    );
    return _searchFoods(uri);
  }

  // ================================

  Future<Food> fetchFoodById(String id) async {
    final url = '$baseUrl/recipes/$id';
    final food = await _getFoodById(url);
    _detailCache[id] = food;
    return food;
  }

  Future<void> createCommunityFood(Map<String, dynamic> recipe) async {
    final token = await TokenStorage().readAccessToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    final response = await appHttpClient.post(
      Uri.parse('$baseUrl/recipes'),
      headers: headers,
      body: jsonEncode(recipe),
    );
    // สูตรใหม่ (เผยแพร่/ร่าง) ต้องโผล่ใน My recipes / Drafts ทันทีที่เปิด
    RecipeLibraryCache.invalidateAll();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = json.decode(response.body);
      final message = body is Map<String, dynamic>
          ? body['message']?.toString()
          : null;
      throw Exception(message ?? appL10n.createRecipeFailed);
    }
  }

  Future<void> updateFood(String id, Map<String, dynamic> recipe) async {
    final token = await TokenStorage().readAccessToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    final response = await appHttpClient.patch(
      Uri.parse('$baseUrl/recipes/$id'),
      headers: headers,
      body: jsonEncode(recipe),
    );
    // แก้แล้ว ของเดิมใน RAM ไม่ตรงแล้ว (เช่น เผยแพร่ร่าง = ย้ายจาก Drafts ไป My recipes)
    _detailCache.remove(id);
    RecipeLibraryCache.invalidateAll();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = json.decode(response.body);
      final message = body is Map<String, dynamic>
          ? body['message']?.toString()
          : null;
      throw Exception(message ?? appL10n.updateRecipeFailed);
    }
  }

  // ============================ อ่านฟังก์ชั่น ==============================

  static PagedResult<Food> _decodePage(String body) {
    return PagedResult.fromJson(
      json.decode(body) as Map<String, dynamic>,
      (item) => Food.fromJson(item, apiBaseUrl: baseUrl),
    );
  }

  static Food _decodeFood(String body) {
    return Food.fromJson(
      json.decode(body) as Map<String, dynamic>,
      apiBaseUrl: baseUrl,
    );
  }

  Future<PagedResult<Food>> _getFoodsPage(Uri uri, {String? cacheKey}) async {
    debugPrint('Fetching foods from: $uri');
    final response = await appHttpClient.get(uri);
    if (response.statusCode == 200) {
      final body = utf8.decode(response.bodyBytes);
      final result = _decodePage(body);
      if (cacheKey != null) unawaited(ApiCache.instance.write(cacheKey, body));
      return result;
    }
    debugPrint('Failed to load foods: ${response.statusCode}');
    throw Exception(appL10n.loadRecipesFailed);
  }

  Future<Food> _getFoodById(String url) async {
    debugPrint('Fetching food from: $url');
    // แนบ token ถ้า login อยู่ สูตรที่ซื้อแล้วจะได้ขั้นตอนครบ (ไม่ login เห็นแค่ preview)
    final token = await TokenStorage().readAccessToken();
    final response = await appHttpClient.get(
      Uri.parse(url),
      headers: token == null || token.trim().isEmpty
          ? null
          : {'Authorization': 'Bearer ${token.trim()}'},
    );

    if (response.statusCode == 200) {
      final body = utf8.decode(response.bodyBytes);
      final food = _decodeFood(body);
      unawaited(ApiCache.instance.write(_detailKey(food.idfoods), body));
      return food;
    } else if (response.statusCode == 404) {
      // ถูกลบ/ซ่อนไปแล้ว ของเก่าในเครื่องไม่ควรโชว์อีก
      final id = Uri.parse(url).pathSegments.last;
      _detailCache.remove(id);
      unawaited(ApiCache.instance.remove(_detailKey(id)));
      throw Exception(appL10n.recipeNotFoundShort);
    } else {
      debugPrint('Failed to load food: ${response.statusCode}');
      throw Exception(appL10n.loadRecipeFailed);
    }
  }

  Future<PagedResult<Food>> _searchFoods(Uri uri) async {
    debugPrint('Searching foods from: $uri');
    final response = await appHttpClient.get(uri);

    if (response.statusCode == 200) {
      return PagedResult.fromJson(
        json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
        (item) => Food.fromJson(item, apiBaseUrl: baseUrl),
      );
    } else if (response.statusCode == 400) {
      // คำค้นหาไม่ผ่าน validation ฝั่ง backend ถือว่าไม่เจอเมนู
      debugPrint('Invalid search query: ${response.body}');
      return const PagedResult(items: [], page: 1, totalPages: 0, total: 0);
    } else {
      debugPrint('Failed to search foods: ${response.statusCode}');
      throw Exception(appL10n.searchRecipesFailed);
    }
  }

  /// ลบได้เฉพาะสูตรของตัวเอง (backend ตรวจจาก token)
  Future<void> deleteFood(String foodId) async {
    final token = await TokenStorage().readAccessToken();
    final response = await appHttpClient.delete(
      Uri.parse('$baseUrl/recipes/$foodId'),
      headers: {
        if (token != null && token.trim().isNotEmpty)
          'Authorization': 'Bearer ${token.trim()}',
      },
    );
    _detailCache.remove(foodId);
    unawaited(ApiCache.instance.remove(_detailKey(foodId)));
    // สูตรที่ลบอาจอยู่ในหลายคลัง (My recipes, Favorites ของคนอื่นในเครื่องเดียวกัน ฯลฯ)
    RecipeLibraryCache.invalidateAll();
    if (response.statusCode != 200) {
      throw Exception(appL10n.deleteRecipeFailed);
    }
  }

  // =====================================================================
}
