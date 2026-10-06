import 'dart:async';

import 'package:flutter_application_1/data/recipe_library_cache.dart';
import 'package:flutter_application_1/repositories/food_repository.dart';
import 'package:flutter_application_1/data/api_cache.dart';

/// ล้างข้อมูลที่เก็บไว้ (RAM และ disk) ซึ่งขึ้นกับว่าใคร login อยู่
/// เรียกหลัง login/register/logout ไม่งั้นบัญชีใหม่จะเห็นข้อมูลของบัญชีเก่าแวบหนึ่ง
/// (หมวดหมู่ไม่ขึ้นกับบัญชี จึงไม่ต้องล้าง)
void clearUserCaches() {
  FoodRepository.clearCache();
  RecipeLibraryCache.clear();
  // โปรไฟล์/สูตรที่ซื้อ/รายละเอียดสูตรที่เก็บบน disk ของบัญชีเก่า
  unawaited(ApiCache.instance.clearUser());
}
