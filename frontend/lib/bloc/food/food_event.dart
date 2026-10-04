abstract class FoodEvent {
  FoodEvent();
}

class FetchFoodEvent extends FoodEvent {
  FetchFoodEvent();
}

class FetchFoodByCategoryEvent extends FoodEvent {
  final String categoryId;
  FetchFoodByCategoryEvent(this.categoryId);
}

class FetchCommunityFoodsByCategoryEvent extends FoodEvent {
  final String categoryId;
  FetchCommunityFoodsByCategoryEvent(this.categoryId);
}

/// โหลดหน้าถัดไปของรายการล่าสุด (ไม่ว่าจะมาจากหมวดหรือการค้นหา)
class FoodLoadMoreRequested extends FoodEvent {
  FoodLoadMoreRequested();
}

/// สูตรถูกลบแล้ว (จากหน้ารายละเอียด) เอาการ์ดออกจากรายการทันที
class FoodRemoved extends FoodEvent {
  final String foodId;
  FoodRemoved(this.foodId);
}

/// อัปเดตรายการล่าสุดเบื้องหลัง (หมวด/คำค้นหาเดิม) ไม่ขึ้นตัวหมุน
/// พลาดก็เก็บรายการเดิมไว้ เช่น ตอนสลับกลับมาแท็บนี้
class FoodSilentRefreshRequested extends FoodEvent {
  FoodSilentRefreshRequested();
}

class SearchFoodEvent extends FoodEvent {
  final String query;
  // หมวดที่เลือกอยู่ ค่าว่าง = ค้นหาทุกหมวด
  final String categoryId;
  final String type;
  SearchFoodEvent(this.query, {this.categoryId = '', this.type = 'official'});
}
