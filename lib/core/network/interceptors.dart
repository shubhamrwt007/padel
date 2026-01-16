import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:padel_mobile/services/network/session_expired_screen.dart';
import '../../configs/components/snack_bars.dart';
import '../../presentations/auth/forgot_password/widgets/forgot_password_exports.dart'
    hide Response;
import '../../services/network/connectivity_service.dart';
import 'dio_client.dart';
class LoggerInterceptor extends Interceptor {
  Logger logger = Logger(
    printer: PrettyPrinter(methodCount: 0, colors: false, printEmojis: true),
  );

  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final requestPath = '${options.baseUrl}${options.path}';
    logger.e('${options.method} request ==> $requestPath');
    logger.d(
      'Error type: ${err.error} \n'
      'Error message: ${err.message}',
    );
    logger.d("TOKEN: ${storage.read('token')}");

    // Handle 401 Unauthorized (Token expired)
    if (err.response?.statusCode == 401) {
      final token = storage.read('token');
      if (token != null && token.isNotEmpty) {
        log("Token expired - redirecting to session expired page");
        await _handleTokenExpiration();
      } else {
        log("No token found, user hasn't logged in yet");
        // Do nothing, let user continue to login/registration flow
      }
      return handler.next(err);
    }
    // Check if it's a connectivity error
    else if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.error is Exception &&
            err.error.toString().contains('SocketException')) {
      await _connectivityService.checkConnectivity();
    // } else if (err.response != null && err.response?.statusCode != 404) {
    //   SnackBarUtils.showErrorSnackBar(
    //     err.response?.data?['message'] ?? 'Api takes to much time to load',
    //   );
    }

    handler.next(err);
  }

  /// Handle token expiration by clearing data and navigating to session expired page
  Future<void> _handleTokenExpiration() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToSessionExpired();
    });
  }

  /// Navigate to session expired page
  void _navigateToSessionExpired() {
    try {
      if (Get.context != null) {
        Get.to(() => SessionExpiredPage());
      }
    } catch (e) {
      log("Error navigating to session expired page: $e");
      Get.to(() => SessionExpiredPage());
    }
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final requestPath = '${options.baseUrl}${options.path}';
    logger.i('${options.method} request ==> $requestPath');
    logger.d("TOKEN: ${storage.read('token')}");

    // Check for connectivity before making the request
    final isConnected = await _connectivityService.checkConnectivity();
    if (!isConnected) {
      // The connectivity service will show the snackbar
      return handler.reject(
        DioException(
          requestOptions: options,
          error: 'No internet connection',
          type: DioExceptionType.connectionError,
        ),
        true,
      );
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    logger.d(
      'STATUSCODE: ${response.statusCode} \n '
      'STATUSMESSAGE: ${response.statusMessage} \n'
      'HEADERS: ${response.headers} \n'
      'Data: ${response.data}',
    );
    logger.d("TOKEN: ${storage.read('token')}");
    handler.next(response);
  }
}
