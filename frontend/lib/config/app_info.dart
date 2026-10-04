/// ข้อมูลแอปที่แสดงในหน้า Settings / เกี่ยวกับแอป
class AppInfo {
  const AppInfo._();

  static const name = 'Recipy';

  /// ต้องตรงกับ version ใน pubspec.yaml
  static const version = '1.0.0';

  /// อีเมลติดต่อทีมงาน (หน้า Help & support)
  /// ว่างไว้ = ยังไม่แสดงช่องทางติดต่อ ใส่อีเมลจริงของทีมก่อนปล่อยแอป
  static const supportEmail = 'aov.support@example.com';
}
