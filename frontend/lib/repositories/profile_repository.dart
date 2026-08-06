import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/user_profile.dart';
import 'package:http/http.dart' as http;

class ProfileRepository {
  const ProfileRepository();

  Future<UserProfile> fetchProfileById() async {
    // Replace this mock with GET /users/me after authentication is connected.
    await Future<void>.delayed(const Duration(milliseconds: 350));

    return const UserProfile(
      id: 'seed-creator',
      displayName: 'Chef Mook',
      email: 'chef@recipy.local',
      avatarAssetPath: 'assets/images/Profile1.jpg',
      roleLabel: 'Recipe creator',
      recipeCount: 12,
      purchasedCount: 8,
      savedCount: 28,
      draftCount: 3,
      rating: 4.9,
    );
  }
  static const String baseUrl = 'http://10.0.2.2:3000';

  // Future<UserProfile> fetchProfile() async {
  //   return _getProfile('$baseUrl/profile');
  // }

  // Future<UserProfile> fetchProfileById(String id) async {
  //   final url = '$baseUrl/recipes/$id';
  //   debugPrint('Fetching profile from: $url');
  //   final response = await http.get(Uri.parse(url));

  //   if (response.statusCode == 200) {
  //     final profile = UserProfile.fromJson(
  //       json.decode(response.body) as Map<String, dynamic>,
  //     );
  //     debugPrint('Parsed profile: ${profile.id} - ${profile.displayName}');
  //     return profile;
  //   } else if (response.statusCode == 404) {
  //     throw Exception('ไม่พบ profile นี้');
  //   } else {
  //     debugPrint('Failed to load profile: ${response.statusCode}');
  //     throw Exception('Failed to load profile');
  //   }
  // }
}
