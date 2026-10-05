/// ตั้งค่าเข้าสู่ระบบด้วย Google
///
/// ค่าอยู่ใน config/dev.json, config/prod.json (ไม่ hard code ในโค้ด)
/// `flutter run --dart-define-from-file=config/dev.json`
///
/// client ID ไม่ใช่ความลับ (อยู่ในแอปที่แจกอยู่แล้ว) จึงเก็บใน repo ได้
/// ความปลอดภัยมาจาก package name + SHA-1 ของแอป และ backend ที่ตรวจ ID token
/// ส่วน client secret ไม่ได้ใช้ ห้ามใส่ในแอป
class GoogleConfig {
  const GoogleConfig._();

  /// Web client ID (Google Cloud → Credentials → OAuth client แบบ Web application)
  /// แอปส่งเป็น serverClientId ค่าเดียวกับ GOOGLE_CLIENT_IDS ใน backend/.env
  /// ว่าง = ปุ่ม Google แจ้งว่ายังไม่เปิดใช้
  static const serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  /// iOS client ID (ใช้เฉพาะ build iOS ยังไม่ได้ตั้งค่า)
  static const iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
}
