import 'package:flutter_application_1/bloc/recipe_library/recipe_library_state.dart';
import 'package:flutter_application_1/models/recipe_collection_type.dart';

/// รายการในคลังสูตร (My recipes / Drafts / Favorites / Purchased) ที่เก็บใน RAM
/// เปิดคลังซ้ำจะโชว์ของเดิมทันทีระหว่างโหลดของใหม่
///
/// ที่ไหนเปลี่ยนข้อมูลของคลัง (กดหัวใจ, ซื้อ, สร้าง/แก้/ลบสูตร) ต้องเรียก [invalidate]
/// ไม่งั้นเปิดคลังจะเห็นของเก่าแวบหนึ่งก่อนอัปเดต
class RecipeLibraryCache {
  RecipeLibraryCache._();

  static final Map<String, CachedCollection> _entries = {};

  static String _key(String userId, RecipeCollectionType type) =>
      '$userId:${type.name}';

  static CachedCollection? read(String userId, RecipeCollectionType type) =>
      _entries[_key(userId, type)];

  static void write(
    String userId,
    RecipeCollectionType type,
    CachedCollection entry,
  ) => _entries[_key(userId, type)] = entry;

  /// ทิ้งรายการของคลังเหล่านี้ (ทุกบัญชี) เปิดครั้งหน้าจะโหลดใหม่
  static void invalidate(Iterable<RecipeCollectionType> types) {
    final suffixes = {for (final type in types) ':${type.name}'};
    _entries.removeWhere(
      (key, _) => suffixes.any((suffix) => key.endsWith(suffix)),
    );
  }

  /// สร้าง/แก้/ลบสูตร กระทบได้ทุกคลัง (เช่น ลบสูตรที่อยู่ใน Favorites)
  static void invalidateAll() => _entries.clear();

  /// เปลี่ยนบัญชี (login/logout)
  static void clear() => _entries.clear();
}

class CachedCollection {
  const CachedCollection(this.state, this.page);

  final RecipeLibraryLoaded state;
  final int page;
}
