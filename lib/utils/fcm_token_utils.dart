import 'package:get/get.dart';
import '../services/fcm_token_service.dart';

class FCMTokenUtils {
  static FCMTokenService get _service => FCMTokenService.instance;

  /// Force update FCM token immediately
  static Future<void> forceUpdate() async {
    await _service.forceTokenUpdate();
  }

  /// Get current stored FCM token
  static String? getCurrentToken() {
    return _service.getCurrentToken();
  }

  /// Refresh token (useful for login/logout scenarios)
  static Future<void> refreshToken() async {
    await _service.refreshToken();
  }
}