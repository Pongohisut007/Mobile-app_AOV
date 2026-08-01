import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_application_1/models/user.dart';
import 'package:http/http.dart' as http;

class UserRepository {
  
  // Base URL for the API
  
  static const String baseUrl = 'https://fakestoreapi.com';


  Future<List<User>> fetchUserEvent() async {
    // Make an HTTP GET request to fetch products from the API
    final response = await http.get(Uri.parse('$baseUrl/users'));
    //debugPrint(response.body);
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }
  
}
