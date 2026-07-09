import 'dart:io';

import 'package:flutter/services.dart';
import 'package:padel_mobile/handler/logger.dart';

/// Reads the Android launch Intent URI directly from MainActivity.
/// This is the most reliable way to capture cold-start deep links on Android.
class NativeDeepLink {
  static const _channel = MethodChannel('com.matchacha.app/deeplink');

  static Future<String?> getInitialLink() async {
    if (!Platform.isAndroid) return null;

    try {
      final link = await _channel.invokeMethod<String>('getInitialLink');
      CustomLogger.logMessage(
        msg: '🔗 Native initial link: $link',
        level: LogLevel.debug,
      );
      return link;
    } catch (e) {
      CustomLogger.logMessage(
        msg: '❌ Native initial link error: $e',
        level: LogLevel.error,
      );
      return null;
    }
  }
}
