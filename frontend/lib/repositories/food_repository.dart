import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/models/food.dart';
import 'package:http/http.dart' as http;

class FoodRepository {
  static const String baseUrl = 'http://10.0.2.2:3000';

  Future<List<Food>> fetchFoods() async {
    return _getFoods('$baseUrl/recipes');
  }


  Future<List<Food>> fetchFoodsByCategoryId(String categoryId) async {
    final url = '$baseUrl/categories/$categoryId';
    debugPrint('Fetching foods by category from: $url');
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final category = json.decode(response.body) as Map<String, dynamic>;
      final recipes = category['recipes'] as List<dynamic>? ?? [];
      final foods = recipes
          .map((json) => Food.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('Parsed ${foods.length} foods in category ${category['name']}');
      return foods;
    } else if (response.statusCode == 404) {
      throw Exception('ไม่พบหมวดหมู่นี้');
    } else {
      debugPrint('Failed to load category: ${response.statusCode}');
      throw Exception('Failed to load foods');
    }
  }

  Future<Food> fetchFoodById(String id) async {
    final url = '$baseUrl/recipes/$id';
    debugPrint('Fetching food from: $url');
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final food = Food.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
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

  Future<List<Food>> _getFoods(String url) async {
    debugPrint('Fetching foods from: $url');
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      final foods = jsonList.map((json) => Food.fromJson(json)).toList();

      debugPrint('Parsed ${foods.length} foods successfully');
      for (var food in foods) {
        debugPrint('  - ${food.idfoods}: ${food.name} (${food.category})');
      }

      return foods;
    } else {
      debugPrint('Failed to load foods: ${response.statusCode}');
      throw Exception('Failed to load foods');
    }
  }
}