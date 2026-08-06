import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/models/food.dart';
import 'package:http/http.dart' as http;

class FoodRepository {
  // Base URL for the API
  // static const String baseUrl = 'http://10.0.2.2:3000';
  static const String baseUrl = 'http://localhost:3000';

  Future<List<Food>> fetchFoods() async {
    return _getFoods('$baseUrl/recipes');
  }

  Future<List<Food>> fetchFoodsByCategory(String category) async {
    return _getFoods('$baseUrl/recipes?category=${Uri.encodeComponent(category)}');
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