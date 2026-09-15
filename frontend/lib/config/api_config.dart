import 'package:flutter/foundation.dart';

class ApiConfig {
  const ApiConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
    //defaultValue: 'http://localhost:3000',
  );

  /// Fake purchases are available in debug/profile builds only unless explicitly
  /// enabled. The backend independently blocks them when NODE_ENV=production.
  static const mockIapEnabled = bool.fromEnvironment(
    'ENABLE_MOCK_IAP',
    defaultValue: !kReleaseMode,
  );
}
