import 'package:flutter_application_1/l10n/l10n.dart';

/// ชิป "ชอบอะไรในสูตรนี้" key ต้องตรงกับ REVIEW_TAGS ฝั่ง backend
class ReviewTag {
  const ReviewTag._();

  /// เรียงตามลำดับที่แสดงในหน้าให้คะแนน
  static const keys = ['tasty', 'easy', 'spicy_right', 'easy_ingredients'];

  /// key ที่แอปไม่รู้จัก (เช่น backend เพิ่มใหม่) ให้โชว์ key ไปก่อน
  static String labelOf(AppLocalizations l10n, String key) => switch (key) {
    'tasty' => l10n.tagTasty,
    'easy' => l10n.tagEasy,
    'spicy_right' => l10n.tagSpicyRight,
    'easy_ingredients' => l10n.tagEasyIngredients,
    _ => key,
  };
}
