import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/cart/cart_bloc.dart';
import 'package:flutter_application_1/bloc/cart/cart_event.dart';
import 'package:flutter_application_1/bloc/favorite/favorite_bloc.dart';
import 'package:flutter_application_1/bloc/favorite/favorite_event.dart';
import 'package:flutter_application_1/bloc/purchased_recipes/purchased_recipes_bloc.dart';
import 'package:flutter_application_1/bloc/purchased_recipes/purchased_recipes_event.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/data/user_cache.dart';
import 'package:flutter_application_1/repositories/auth_repository.dart';
import 'package:flutter_application_1/repositories/google_sign_in_service.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_application_1/routes/app_routes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// ล้าง session บนเครื่องนี้แล้วกลับหน้าแรก
/// ใช้ร่วมกันตอน Sign out / ออกจากระบบทุกอุปกรณ์ / ลบบัญชี
Future<void> signOutLocally(BuildContext context) async {
  // bloc เหล่านี้อยู่เหนือ MaterialApp จึงอ่านได้จากทุกหน้า
  final cartBloc = context.read<CartBloc>();
  final favoriteBloc = context.read<FavoriteBloc>();
  final purchasedRecipesBloc = context.read<PurchasedRecipesBloc>();
  final navigator = Navigator.of(context);

  final storage = TokenStorage();
  // ให้ backend ยกเลิก token ใบนี้ด้วย (หลุดไปอยู่ที่อื่นก็ใช้ไม่ได้แล้ว)
  // ไม่รอผล: ไม่มีเน็ต/token หมดอายุไปแล้ว ก็ยังออกจากระบบในเครื่องได้ทันที
  final accessToken = await storage.readAccessToken();
  if (accessToken != null && accessToken.trim().isNotEmpty) {
    unawaited(
      HttpAuthRepository(
        baseUrl: ApiConfig.apiBaseUrl,
      ).logout(accessToken: accessToken).catchError((Object _) {}),
    );
  }
  await storage.clearSession();
  // ครั้งหน้ากด "เข้าสู่ระบบด้วย Google" จะได้เลือกบัญชีใหม่
  await GoogleSignInService.instance.signOut();
  clearUserCaches();
  // อ่าน token ไม่เจอแล้ว ทุก bloc จะล้าง state ของคนเก่าทิ้งเอง
  cartBloc.add(const CartRequested());
  favoriteBloc.add(const FavoritesRequested());
  purchasedRecipesBloc.add(const PurchasedRecipesRequested());
  navigator.pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
}
