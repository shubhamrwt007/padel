import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:padel_mobile/handler/logger.dart';
import 'package:padel_mobile/services/network/session_expired_screen.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../../configs/components/snack_bars.dart';
import '../../presentations/auth/forgot_password/widgets/forgot_password_exports.dart'
    hide Response;
import '../../services/network/connectivity_service.dart';
import 'dio_client.dart';

class LoggerInterceptor extends Interceptor {
  final _prettyLogger = PrettyDioLogger(
    requestHeader: true,
    requestBody: true,
    responseBody: true,
    responseHeader: false,
    error: true,
    compact: true,
  );

  final ConnectivityService _connectivityService = ConnectivityService();
  String? _getToken() => storage.read('token');
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final token = _getToken();
    _highlightLog("🔴 ==============================");
    _highlightLog("🔴 ERROR TOKEN: $token");
    _highlightLog("🔴 ==============================");

    // Handle 401 Unauthorized (Token expired)
    if (err.response?.statusCode == 401) {
      final token = storage.read('token');
      if (token != null && token.isNotEmpty) {
        log("Token expired - redirecting to session expired page");
        await _handleTokenExpiration();
      } else {
        log("No token found, user hasn't logged in yet");
      }
    }

    // Check if it's a connectivity error
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.error is Exception && err.error.toString().contains('SocketException')) {
      await _connectivityService.checkConnectivity();
    }

    _prettyLogger.onError(err, handler);
  }

  Future<void> _handleTokenExpiration() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToSessionExpired();
    });
  }

  void _navigateToSessionExpired() {
    try {
      if (Get.context != null) {
        Get.offAll(() => SessionExpiredPage());
      }
    } catch (e) {
      log("Error navigating to session expired page: $e");
      Get.offAll(() => SessionExpiredPage());
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = _getToken();
    _highlightLog("🟡 ==============================");
    _highlightLog("🟡 REQUEST TOKEN: $token}");
    _highlightLog("🟡 ==============================");

    final isConnected = await _connectivityService.checkConnectivity();
    if (!isConnected) {
      return handler.reject(
        DioException(
          requestOptions: options,
          error: 'No internet connection',
          type: DioExceptionType.connectionError,
        ),
        true,
      );
    }

    _prettyLogger.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    final token = _getToken();
    _highlightLog("🟢 ==============================");
    _highlightLog("🟢 RESPONSE TOKEN: $token");
    _highlightLog("🟢 ==============================");

    _prettyLogger.onResponse(response, handler);
  }
  void _highlightLog(String message) {
    const yellow = '\x1B[33m';
    const green = '\x1B[32m';
    const red = '\x1B[31m';
    const cyan = '\x1B[36m';
    const reset = '\x1B[0m';

    print('$cyan$message$reset');
  }

}
