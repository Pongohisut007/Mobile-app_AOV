import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/models/food.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:http/http.dart' as http;

class FoodRepository {
  static const String baseUrl = ApiConfig.apiBaseUrl;
  //static const String baseUrl = 'http://localhost:3000';

  // =========================== เรียกใช้ตรงนี้ ==================================

  Future<List<Food>> fetchFoodsByCategoryId(String categoryId) async {
    final url = '$baseUrl/categories/$categoryId';
    return _getFoodsByCategoryId(url);
  }

  Future<List<Food>> fetchCommunityFoodsByCategoryId(String categoryId) async {
    final url = '$baseUrl/categories/$categoryId?type=community';
    return _getFoodsByCategoryId(url);
  }

  Future<List<Food>> fetchOfficialFoodsByCategoryId(String categoryId) async {
    final url = '$baseUrl/categories/$categoryId?type=official';
    return _getFoodsByCategoryId(url);
  }

  // ================================

  Future<List<Food>> fetchCommuityAllFoodsByCategoryId() async {
    final url = '$baseUrl/categories?type=community';
    return _getAllFoodsByCategoryId(url);
  }

  Future<List<Food>> fetchOfficialAllFoodsByCategoryId() async {
    final url = '$baseUrl/categories?type=official';
    return _getAllFoodsByCategoryId(url);
  }

  // ================================

  Future<List<Food>> fetchFoods() async {
    return _getFoods('$baseUrl/recipes');
  }

  Future<List<Food>> fetchCommunityFoods() async {
    return _getFoods('$baseUrl/recipes?type=community');
  }

  Future<List<Food>> fetchOfficialFoods() async {
    return _getFoods('$baseUrl/recipes?type=official');
  }

  // ================================

  Future<List<Food>> searchFoods(
    String query, {
    String? type,
    String? categoryId,
  }) async {
    final uri = Uri.parse('$baseUrl/recipes/search').replace(
      queryParameters: {
        'q': query,
        'type': ?type,
        'categoryId': ?categoryId,
        'limit': '50', // backend จำกัดไว้สูงสุด 50
      },
    );
    return _searchFoods(uri);
  }

  // ================================

  Future<Food> fetchFoodById(String id) async {
    final url = '$baseUrl/recipes/$id';
    return _getFoodById(url);
  }

  Future<void> createCommunityFood(Map<String, dynamic> recipe) async {
    final token = await TokenStorage().readAccessToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    final response = await http.post(
      Uri.parse('$baseUrl/recipes'),
      headers: headers,
      body: jsonEncode(recipe),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = json.decode(response.body);
      final message = body is Map<String, dynamic>
          ? body['message']?.toString()
          : null;
      throw Exception(message ?? 'สร้างสูตรอาหารไม่สำเร็จ');
    }
  }

  // ============================ อ่านฟังก์ชั่น ==============================

  Future<List<Food>> _getAllFoodsByCategoryId(String url) async {
    debugPrint('Fetching from: $url');
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> categories = json.decode(response.body);
      final foods = <Food>[];
      for (final cat in categories) {
        final recipes =
            (cat as Map<String, dynamic>)['recipes'] as List<dynamic>? ?? [];
        foods.addAll(
          recipes.map(
            (r) =>
                Food.fromJson(r as Map<String, dynamic>, apiBaseUrl: baseUrl),
          ),
        );
      }
      return foods;
    } else {
      throw Exception('Failed to load foods');
    }
  }

  Future<List<Food>> _getFoodsByCategoryId(String url) async {
    debugPrint('Fetching foods by category from: $url');
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final category = json.decode(response.body) as Map<String, dynamic>;
      final recipes = category['recipes'] as List<dynamic>? ?? [];
      final foods = recipes
          .map(
            (json) => Food.fromJson(
              json as Map<String, dynamic>,
              apiBaseUrl: baseUrl,
            ),
          )
          .toList();
      // debugPrint(
      //   'Parsed ${foods.length} foods in category ${category['name']}',
      // );
      return foods;
    } else if (response.statusCode == 404) {
      throw Exception('ไม่พบหมวดหมู่นี้');
    } else {
      debugPrint('Failed to load category: ${response.statusCode}');
      throw Exception('Failed to load foods');
    }
  }

  Future<Food> _getFoodById(String url) async {
    debugPrint('Fetching food from: $url');
    // แนบ token ถ้า login อยู่ สูตรที่ซื้อแล้วจะได้ขั้นตอนครบ (ไม่ login เห็นแค่ preview)
    final token = await TokenStorage().readAccessToken();
    final response = await http.get(
      Uri.parse(url),
      headers: token == null || token.trim().isEmpty
          ? null
          : {'Authorization': 'Bearer ${token.trim()}'},
    );

    if (response.statusCode == 200) {
      final food = Food.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
        apiBaseUrl: baseUrl,
      );
      debugPrint('Parsed food: ${food.idfoods} - ${food.name}');
      return food;
    } else if (response.statusCode == 404) {
      throw Exception('ไม่พบเมนูนี้');
    } else {
      debugPrint('Failed to load food: ${response.statusCode}');
      throw Exception('Failed to load food');
    }
  }

  Future<List<Food>> _searchFoods(Uri uri) async {
    debugPrint('Searching foods from: $uri');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      // /recipes/search ห่อผลลัพธ์ไว้ใน data ไม่ได้คืน array ตรง ๆ เหมือน /recipes
      final body = json.decode(response.body) as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>? ?? const [];
      return data
          .map(
            (json) => Food.fromJson(
              json as Map<String, dynamic>,
              apiBaseUrl: baseUrl,
            ),
          )
          .toList();
    } else if (response.statusCode == 400) {
      // คำค้นหาไม่ผ่าน validation ฝั่ง backend ถือว่าไม่เจอเมนู
      debugPrint('Invalid search query: ${response.body}');
      return const [];
    } else {
      debugPrint('Failed to search foods: ${response.statusCode}');
      throw Exception('Failed to search foods');
    }
  }

  Future<List<Food>> _getFoods(String url) async {
    debugPrint('Fetching foods from: $url');
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      final foods = jsonList
          .map((json) => Food.fromJson(json, apiBaseUrl: baseUrl))
          .toList();
      // debugPrint('Parsed ${foods.length} foods successfully');
      // for (var food in foods) {
      //   debugPrint('  - ${food.idfoods}: ${food.name} (${food.category})');
      // }
      return foods;
    } else {
      debugPrint('Failed to load foods: ${response.statusCode}');
      throw Exception('Failed to load foods');
    }
  }

  Future<void> deleteFood(String foodId) async {
    final response = await http.delete(Uri.parse('$baseUrl/recipes/$foodId'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete food');
    }
  }

  // =====================================================================
}
