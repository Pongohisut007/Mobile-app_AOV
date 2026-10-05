import 'package:flutter/foundation.dart';

class ApiConfig {
  const ApiConfig._();

  /// ค่าอยู่ใน config/dev.json, config/prod.json (ไม่ hard code ในโค้ด)
  /// `flutter run --dart-define-from-file=config/dev.json`
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Fake purchases are available in debug/profile builds only unless explicitly
  /// enabled. The backend independently blocks them when APP_ENV=production.
  static const mockIapEnabled = bool.fromEnvironment(
    'ENABLE_MOCK_IAP',
    defaultValue: !kReleaseMode,
  );
}
