class ApiConfig {
  const ApiConfig._();

  /// ค่าอยู่ใน config/dev.json, config/prod.json (ไม่ hard code ในโค้ด)
  /// `flutter run --dart-define-from-file=config/dev.json`
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// ซื้อจำลองเปิดทุก environment รวม production (ยังไม่มีระบบจ่ายเงินจริง)
  /// ปิดได้ด้วย ENABLE_MOCK_IAP=false ใน config ถ้าวันหน้ามี billing จริง
  static const mockIapEnabled = bool.fromEnvironment(
    'ENABLE_MOCK_IAP',
    defaultValue: true,
  );
}
