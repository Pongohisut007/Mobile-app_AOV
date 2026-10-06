import 'package:flutter/widgets.dart';

/// เปิดหน้าใหม่ / bottom sheet / dialog ทับ = ปล่อยช่องพิมพ์ที่กำลัง focus อยู่ก่อน
///
/// ไม่งั้นพอกลับมาหน้าเดิม Flutter จะคืน focus ให้ช่องเดิมเอง คีย์บอร์ดเด้งขึ้นมา
/// ทั้งที่ผู้ใช้ไม่ได้แตะช่องนั้น (เช่น พิมพ์ชื่อสูตรค้างไว้ → ไปหน้าขั้นตอน → กลับมา)
/// ใส่ไว้ที่ MaterialApp จุดเดียว ใช้ได้ทุกหน้า
class UnfocusOnNavigateObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // หน้าแรกของแอปไม่มีอะไรให้ปล่อย
    if (previousRoute == null) return;
    // focus ย้ายไปอยู่ที่ระดับหน้าแทนช่องพิมพ์ หน้าเดิมจึงไม่มีช่องให้คืน focus ตอนกลับมา
    FocusManager.instance.primaryFocus?.unfocus();
  }
}
