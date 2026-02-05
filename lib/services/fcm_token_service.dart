import 'dart:async';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:padel_mobile/repositories/authentication_repository/fcm_token_repository.dart';
import '../core/network/dio_client.dart';
import '../core/endpoitns.dart';
import 'notification_service/firebase_notification.dart';

class FCMTokenService extends GetxService {
  static FCMTokenService get instance => Get.find<FCMTokenService>();

  final DioClient _dioClient = Get.find<DioClient>();
  final GetStorage _storage = GetStorage();
  final NotificationService _notificationService = NotificationService();

  Timer? _tokenUpdateTimer;
  String? _currentToken;

  static const String _tokenKey = 'fcm_token';
  static const String _lastUpdateKey = 'fcm_token_last_update';
  static const Duration _updateInterval = Duration(hours: 2);

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeTokenService();
  }

  Future<void> _initializeTokenService() async {
    try {
      // Get initial token
      await _updateToken();

      // Start periodic updates
      _startPeriodicUpdates();

      log('FCM Token Service initialized successfully');
    } catch (e) {
      log('Failed to initialize FCM Token Service: $e');
    }
  }

  void _startPeriodicUpdates() {
    _tokenUpdateTimer?.cancel();
    _tokenUpdateTimer = Timer.periodic(_updateInterval, (_) async {
      await _updateToken();
    });
    log('Started periodic FCM token updates every ${_updateInterval.inMilliseconds} hours');
  }

  Future<void> _updateToken() async {
    log('Function Start');
    try {
      final String? newToken = await _notificationService.getFirebaseToken();
      log('new token $newToken');
      if (newToken == null || newToken.isEmpty) {
        log('Failed to get FCM token');
        return;
      }

      final String? storedToken = _storage.read(_tokenKey);

      // Only update if token changed or it's been more than 2 hours
      if (_shouldUpdateToken(newToken, storedToken)) {
        log('_sendTokenToBackend function');
        final bool success = await _sendTokenToBackend(newToken);

        if (success) {
          _currentToken = newToken;
          _storage.write(_tokenKey, newToken);
          _storage.write(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
          log('FCM token updated successfully');
        }
      }
    } catch (e) {
      log('Error updating FCM token: $e');
    }
  }

  bool _shouldUpdateToken(String newToken, String? storedToken) {
    if (storedToken != newToken) return true;

    final int? lastUpdate = _storage.read(_lastUpdateKey);
    if (lastUpdate == null) return true;

    final DateTime lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(lastUpdate);
    final Duration timeSinceUpdate = DateTime.now().difference(lastUpdateTime);

    return timeSinceUpdate >= _updateInterval;
  }

  final FcmTokenRepository repository = Get.put(FcmTokenRepository());
  Future<bool> _sendTokenToBackend(String token) async {
    log('_sendTokenToBackend Api -Log');
    try {
      log('TOken-> $token');
      final body = {
        'fcmToken': token,
      };
      final response = await repository.updateFcmToken(body: body);
      if (response.status == 200) {
        log('FCM token sent to backend successfully');
        return true;
      } else {
        log('Failed to send FCM token: ${response.status}');
        return false;
      }
    } catch (e) {
      log('Error sending FCM token to backend: $e');
      return false;
    }
  }

  // Public methods
  Future<void> forceTokenUpdate() async {
    log('Force updating FCM token...');
    await _updateToken();
  }

  String? getCurrentToken() => _currentToken ?? _storage.read(_tokenKey);

  Future<void> refreshToken() async {
    await _updateToken();
  }

  @override
  void onClose() {
    _tokenUpdateTimer?.cancel();
    super.onClose();
  }
}