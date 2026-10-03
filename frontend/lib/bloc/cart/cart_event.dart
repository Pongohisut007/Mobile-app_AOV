import 'package:flutter_application_1/models/food.dart';

sealed class CartEvent {
  const CartEvent();
}

/// อ่าน token จากเครื่องแล้วโหลดตะกร้าของคนนั้นใหม่ทั้งหมด
/// ไม่มี token = ตะกร้าว่าง จึงใช้ตัวนี้ได้ทั้งตอนล็อกอิน สลับบัญชี และ logout
final class CartRequested extends CartEvent {
  const CartRequested();
}

/// กดปุ่ม + บนการ์ด ถ้าสูตรนี้อยู่ในตะกร้าแล้วจะไม่เพิ่มซ้ำ
final class CartItemAdded extends CartEvent {
  const CartItemAdded(this.food, {this.showFeedback = true});

  final Food food;

  /// false = ไม่ต้องเด้ง SnackBar เพราะหน้าที่กดแสดงผลเอง (เช่น animation หน้า detail)
  final bool showFeedback;
}

/// [itemId] คือ id ของแถวในตะกร้า (CartItem.id) ไม่ใช่ id สูตร
final class CartItemRemoved extends CartEvent {
  const CartItemRemoved(this.itemId);

  final String itemId;
}

final class CartCleared extends CartEvent {
  const CartCleared();
}
