import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/app_notification.dart';
import 'package:flutter_application_1/views/pages/food_detail_page.dart';

/// หน้าที่เปิดเมื่อกดแจ้งเตือน (ในกล่องแจ้งเตือนหรือจาก push)
/// คอมเมนต์ใหม่ = เลื่อนลงไปที่คอมเมนต์ให้เลย
Route<void> notificationRecipeRoute(String recipeId, AppNotificationType type) {
  return MaterialPageRoute<void>(
    builder: (_) => FoodDetailPage(
      foodsId: recipeId,
      scrollToComments: type == AppNotificationType.recipeCommented,
    ),
  );
}
