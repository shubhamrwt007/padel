import 'dart:async';
import 'dart:io';
import 'package:app_links/app_links.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';
import 'package:padel_mobile/handler/logger.dart';

class DeepLinkService extends GetxService with WidgetsBindingObserver {
  static DeepLinkService get instance => Get.find<DeepLinkService>();

  static const _channel = MethodChannel('com.matchacha.app/deeplink');
  StreamSubscription? _linkSubscription;
  String? _pendingLink;

  Future<DeepLinkService> init() async {
    WidgetsBinding.instance.addObserver(this);
    try {
      if (Platform.isAndroid) {
        _channel.setMethodCallHandler((call) async {
          if (call.method == 'onNewLink') {
            final link = call.arguments as String?;
            if (link != null && link.isNotEmpty) {
              CustomLogger.logMessage(msg: '🔗 Android onNewLink: $link', level: LogLevel.debug);
              _dispatchLink(link);
            }
          }
        });
      }
      else {
        // iOS: SplashController owns getInitialLink — never call it here.
        // Skip any link that splash already consumed to avoid double-navigation.
        _linkSubscription = AppLinks().uriLinkStream.listen(
          (uri) {
            final link = uri.toString();
            final consumed = GetStorage().read<String>('_splashConsumedLink') ?? '';
            if (consumed == link) {
              GetStorage().remove('_splashConsumedLink');
              return;
            }
            CustomLogger.logMessage(msg: '🔗 iOS app_links: $uri', level: LogLevel.debug);
            _dispatchLink(link);
          },
          onError: (err) {
            CustomLogger.logMessage(msg: '❌ Link stream error: $err', level: LogLevel.error);
          },
        );
      }
      CustomLogger.logMessage(msg: '✅ DeepLinkService initialized', level: LogLevel.debug);
    } catch (e)
    {
      CustomLogger.logMessage(msg: '❌ DeepLinkService init error: $e', level: LogLevel.error);
    }
    return this;
  }

  /// Waits until app is resumed before navigating
  void _dispatchLink(String link) {
    final state = WidgetsBinding.instance.lifecycleState;
    if (state == AppLifecycleState.resumed) {
      handleDeepLink(link);
    } else {
      // App is in background/inactive — store and handle once resumed
      _pendingLink = link;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _pendingLink != null) {
      final link = _pendingLink!;
      _pendingLink = null;
      // Small delay to ensure navigator is ready after resume
      Future.delayed(const Duration(milliseconds: 300),
              () => handleDeepLink(link));
    }
  }
  void handleDeepLink(String link) {
    try {
      final uri = Uri.parse(link);
      final path = uri.path;
      final params = uri.queryParameters;
      final token = GetStorage().read<String>('token') ?? '';
      CustomLogger.logMessage(msg: '🔗 Handling: $path', level: LogLevel.debug);
      if (path.contains('open-match-payment')) {
        final paymentId = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
        if (paymentId.isNotEmpty) {
          if (token.isNotEmpty) {
            Get.toNamed(RoutesName.sharePayment, arguments: {'paymentId': paymentId});
          } else {
            GetStorage().write('pendingPaymentId', paymentId);
            Get.offAllNamed(RoutesName.login);
          }
        }
      } else if (path.contains('sharePayment') || path.contains('share-payment')) {
        final matchId = params['matchId'] ?? params['id'] ?? '';
        if (matchId.isNotEmpty) {
          Get.toNamed(RoutesName.sharePayment, arguments: {'matchId': matchId});
        }
      }
    } catch (e) {
      CustomLogger.logMessage(msg: '❌ Error handling deep link: $e', level: LogLevel.error);
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSubscription?.cancel();
    super.onClose();
  }
}
