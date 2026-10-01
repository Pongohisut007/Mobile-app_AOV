/// ชิป "ชอบอะไรในสูตรนี้" key ต้องตรงกับ REVIEW_TAGS ฝั่ง backend
class ReviewTag {
  const ReviewTag._();

  static const options = <String, String>{
    'tasty': 'รสชาติดี',
    'easy': 'ทำง่าย',
    'spicy_right': 'เผ็ดกำลังดี',
    'easy_ingredients': 'วัตถุดิบหาง่าย',
  };

  /// key ที่แอปไม่รู้จัก (เช่น backend เพิ่มใหม่) ให้โชว์ key ไปก่อน
  static String labelOf(String key) => options[key] ?? key;
}
