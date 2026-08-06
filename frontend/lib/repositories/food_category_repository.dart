import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/models/food_category.dart';
import 'package:http/http.dart' as http;

class FoodCategoryRepository {
  // Base URL for the API
  // static const String baseUrl = 'http://10.0.2.2:3000';
  static const String baseUrl = 'http://localhost:3000';

  Future<List<FoodCategory>> fetchFoodCategories() async {
    return _getCategories('$baseUrl/categories');
  }

  Future<List<FoodCategory>> fetchFoodCategoriesByCategory(String category) async {
    return _getCategories('$baseUrl/categories/${Uri.encodeComponent(category)}');
  }

  Future<List<FoodCategory>> _getCategories(String url) async {
    debugPrint('Fetching categories from: $url');
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      final categories = jsonList.map((json) => FoodCategory.fromJson(json)).toList();

      debugPrint('Parsed ${categories.length} categories successfully');
      for (var category in categories) {
        debugPrint('  - ${category.id}: ${category.name}');
      }

      return categories;
    } else {
      debugPrint('Failed to load categories: ${response.statusCode}');
      throw Exception('Failed to load categories');
    }
  }

  Future<int> fetchCategoryCount() async {
    final url = '$baseUrl/categories/count';
    debugPrint('Fetching category count from: $url');
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final count = jsonResponse['count'] as int;
      debugPrint('Fetched category count: $count');
      return count;
    } else {
      debugPrint('Failed to load category count: ${response.statusCode}');
      throw Exception('Failed to load category count');
    }
  }
}