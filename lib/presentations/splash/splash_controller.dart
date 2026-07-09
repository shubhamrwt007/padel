import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:padel_mobile/configs/components/app_toast.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../configs/components/snack_bars.dart';
import '../../configs/routes/routes_name.dart';
import '../../handler/logger.dart';
import '../../repositories/app_version_repository/app_version_repository.dart';
import '../../services/network/connectivity_service.dart';
import '../auth/login/widgets/login_exports.dart';
import 'widgets/force_update_dialog.dart';

class SplashController extends GetxController {
  final ConnectivityService _connectivityService = ConnectivityService();
  final AppVersionRepository _appVersionRepository = AppVersionRepository();

  @override
  void onInit() {
    super.onInit();
    _start();
  }

  Future<void> _start() async {
    await WidgetsBinding.instance.endOfFrame;

    Uri? coldLink;
    try {
      String? linkStr;
      if (Platform.isAndroid) {
        const channel = MethodChannel('com.matchacha.app/deeplink');
        final completer = Completer<String?>();
        channel.setMethodCallHandler((call) async {
          if (call.method == 'onNewLink' && !completer.isCompleted) {
            completer.complete(call.arguments as String?);
          }
        });
        linkStr = await completer.future.timeout(
          const Duration(seconds: 2),
          onTimeout: () => null,
        );
        channel.setMethodCallHandler(null);
      } else {
        // iOS: read from AppDelegate via MethodChannel (same pattern as Android)
        // AppDelegate captures the Universal Link from launchOptions before Flutter starts
        const channel = MethodChannel('com.matchacha.app/deeplink');
        linkStr = await channel.invokeMethod<String>('getInitialLink');
        // Mark consumed so DeepLinkService skips it
        if (linkStr != null && linkStr.isNotEmpty) {
          GetStorage().write('_splashConsumedLink', linkStr);
        }
      }
      CustomLogger.logMessage(msg: '🔗 Raw linkStr from channel: $linkStr', level: LogLevel.debug);
      if (linkStr != null && linkStr.isNotEmpty) {
        coldLink = Uri.tryParse(linkStr);
      }
      CustomLogger.logMessage(msg: '🔗 Cold-start link parsed: $coldLink', level: LogLevel.debug);
    } catch (e) {
      CustomLogger.logMessage(msg: '❌ getInitialLink: $e', level: LogLevel.error);
    }

    // Check install referrer on Android (deferred deep link — user had no app installed)
    if (Platform.isAndroid && coldLink == null) {
      final alreadyChecked = GetStorage().read<bool>('referrer_checked') ?? false;
      if (!alreadyChecked) {
        await GetStorage().write('referrer_checked', true);
        try {
          const channel = MethodChannel('com.matchacha.app/deeplink');
          final referrer = await channel.invokeMethod<String>('getInstallReferrer');
          CustomLogger.logMessage(msg: '🔗 Install referrer: $referrer', level: LogLevel.debug);
          if (referrer != null && referrer.isNotEmpty) {
            final params = Uri.splitQueryString(referrer);
            final paymentId = params['paymentId'] ?? referrer;
            if (paymentId.isNotEmpty) {
              await Future.delayed(const Duration(seconds: 3));
              final token = GetStorage().read<String>('token') ?? '';
              if (token.isNotEmpty) {
                Get.offAllNamed(RoutesName.sharePayment, arguments: {'paymentId': paymentId});
              } else {
                GetStorage().write('pendingPaymentId', paymentId);
                Get.offAllNamed(RoutesName.login);
              }
              return;
            }
          }
        } catch (e) {
          CustomLogger.logMessage(msg: '❌ getInstallReferrer: $e', level: LogLevel.error);
        }
      }
    }

    await Future.delayed(const Duration(seconds: 3));

    // If opened via deep link, skip version check and navigate directly
    if (coldLink != null) {
      _handleDeepLink(coldLink);
      return;
    }

    final hasInternet = await _connectivityService.checkConnectivity();
    if (!hasInternet) {
      AppToast.error("You're offline. Some features may not work properly.");
      _navigateDefault();
      return;
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final response = await _appVersionRepository.checkAppVersion(
        body: {
          'platform': Platform.isAndroid ? 'android' : 'ios',
          'currentVersion': packageInfo.version,
        },
      );

      if (response.forceUpdate == true) {
        Get.dialog(
          ForceUpdateDialog(latestVersion: response.data?.latestVersion ?? ''),
          barrierDismissible: false,
        );
      } else if (response.updateRequired == true) {
        _showOptionalUpdateDialog(response.data?.latestVersion ?? '');
      } else {
        _navigateDefault();
      }
    } catch (e) {
      CustomLogger.logMessage(msg: 'Version check error: $e', level: LogLevel.error);
      _navigateDefault();
    }
  }

  // Safety net — called if _start() throws unexpectedly so splash never gets stuck
  @override
  void onReady() {
    super.onReady();
    Future.delayed(const Duration(seconds: 10), () {
      if (Get.currentRoute == RoutesName.splash || Get.currentRoute == '/') {
        CustomLogger.logMessage(msg: '⚠️ Splash watchdog triggered — forcing navigation', level: LogLevel.warning);
        _navigateDefault();
      }
    });
  }

  void _handleDeepLink(Uri uri) {
    final path = uri.path;
    final params = uri.queryParameters;
    final token = GetStorage().read<String>('token') ?? '';

    CustomLogger.logMessage(msg: '🔗 Deep link path: $path', level: LogLevel.debug);

    if (path.contains('open-match-payment')) {
      final paymentId = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
      if (paymentId.isNotEmpty) {
        if (token.isNotEmpty) {
          Get.offAllNamed(RoutesName.sharePayment, arguments: {'paymentId': paymentId});
        } else {
          GetStorage().write('pendingPaymentId', paymentId);
          Get.offAllNamed(RoutesName.login);
        }
        return;
      }
    } else if (path.contains('sharePayment') || path.contains('share-payment')) {
      final matchId = params['matchId'] ?? params['id'] ?? '';
      if (matchId.isNotEmpty) {
        if (token.isNotEmpty) {
          Get.offAllNamed(RoutesName.sharePayment, arguments: {'matchId': matchId});
        } else {
          GetStorage().write('pendingPaymentId', matchId);
          Get.offAllNamed(RoutesName.login);
        }
        return;
      }
    }

    // Unknown deep link path — fall through to default
    _navigateDefault();
  }

  void _navigateDefault() {
    final token = GetStorage().read<String>('token') ?? '';
    CustomLogger.logMessage(msg: 'TOKEN: $token', level: LogLevel.info);

    // Check for a payment notification that arrived while the app was closed
    final pendingNotifPaymentId =
        GetStorage().read<String>('pendingPaymentNotificationId') ?? '';
    if (pendingNotifPaymentId.isNotEmpty) {
      GetStorage().remove('pendingPaymentNotificationId');
      if (token.isNotEmpty) {
        Get.offAllNamed(RoutesName.sharePayment,
            arguments: {'paymentId': pendingNotifPaymentId});
      } else {
        GetStorage().write('pendingPaymentId', pendingNotifPaymentId);
        Get.offAllNamed(RoutesName.login);
      }
      return;
    }

    if (token.isNotEmpty) {
      Get.offAllNamed(RoutesName.bottomNav);
    } else {
      Get.offAllNamed(RoutesName.login);
    }
  }

  void _showOptionalUpdateDialog(String latestVersion) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Update Available', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('A new version ($latestVersion) is available. Would you like to update now?'),
        actions: [
          TextButton(
            onPressed: () { Get.back(); _navigateDefault(); },
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () { Get.back(); _openStore(); },
            child: const Text('Update'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  void _openStore() async {
    final url = Platform.isAndroid
        ? Uri.parse('https://play.google.com/store/search?q=swoot&c=apps')
        : Uri.parse('https://apps.apple.com/app/id6747494631');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      CustomLogger.logMessage(msg: 'Error opening store: $e', level: LogLevel.error);
    }
  }
}
