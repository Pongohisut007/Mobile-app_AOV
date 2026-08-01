import 'dart:convert';
import 'package:flutter_application_1/models/product.dart';
import 'package:http/http.dart' as http;

class ProductRepository {
  
  // Base URL for the API
  static const String baseUrl = 'https://fakestoreapi.com';

  Future<List<Product>> fetchProducts() async {
    // Make an HTTP GET request to fetch products from the API
    final response = await http.get(Uri.parse('$baseUrl/products'));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }
  
}
