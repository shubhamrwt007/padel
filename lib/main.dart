import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:padel_mobile/firebase_options.dart';
import 'package:padel_mobile/handler/logger.dart';
import 'package:padel_mobile/presentations/notification/notification_controller.dart';
import 'package:padel_mobile/services/notification_service/firebase_notification.dart';
import 'package:padel_mobile/services/fcm_token_service.dart';
import 'package:padel_mobile/services/socket_service.dart';
import 'package:padel_mobile/services/deep_link_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'configs/routes/routes.dart';
import 'configs/themes/app_themes.dart';
import 'presentations/splash/splash_screen.dart';
import 'core/network/dio_client.dart';

/// Background message handler - must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDebugMode) {
    print('📱 Background message: ${message.messageId}');
  }

  try {
    await NotificationService().initialize();

    if (message.notification != null || message.data.isNotEmpty) {
      final payload = message.data.entries.map((e) => '${e.key}=${e.value}').join('|');
      await NotificationService().showNotification(
        id: message.hashCode.abs(),
        title: message.notification?.title ?? 'New Notification',
        body: message.notification?.body ?? 'You have a new message',
        payload: payload,
        highPriority: true,
      );
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Error in background handler: $e');
    }
  }
}

Future<void> main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    CustomLogger.logMessage(msg: '✅ Firebase initialized',level: LogLevel.debug);

    // Initialize timezone data for scheduled notifications
    tz.initializeTimeZones();
    CustomLogger.logMessage(msg: '✅ Timezone initialized',level: LogLevel.debug);

    // Initialize GetStorage
    await GetStorage.init();
    CustomLogger.logMessage(msg: '✅ GetStorage initialized',level: LogLevel.debug);

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    if (kDebugMode) {
      print('✅ Background message handler set');
    }

    // Initialize core services
    Get.put(DioClient());
    Get.put(SocketService());
    Get.put(NotificationController());
    Get.put(FCMTokenService());

    runApp(const MyApp());

  } catch (e) {
    if (kDebugMode) {
      print('❌ Error during app initialization: $e');
    }
    // You might want to show an error screen or handle this differently
    runApp(ErrorApp(error: e.toString()));
  }
}
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // DeepLinkService is initialized after the splash navigates away,
    // so it never races with the cold-start link handling in SplashController.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 6), () {
        if (!Get.isRegistered<DeepLinkService>()) {
          Get.putAsync(() => DeepLinkService().init());
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Swoot',
      theme: AppThemes.appTheme,
      darkTheme: ThemeData.light(),
      themeMode: ThemeMode.light,
      getPages: Routes.route,
      initialRoute: Routes.initialRoute,
      unknownRoute: GetPage(name: '/not-found', page: () => const SplashScreen()),
      navigatorKey: Get.key,
      builder: (context, child) {
        return NotificationWrapper(child: child!);
      },
    );
  }
}

/// Wrapper to handle notification-related app lifecycle
class NotificationWrapper extends StatefulWidget {
  final Widget child;

  const NotificationWrapper({super.key, required this.child});

  @override
  State<NotificationWrapper> createState() => _NotificationWrapperState();
}

class _NotificationWrapperState extends State<NotificationWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _handleAppLaunchFromNotification();
  }

  @override

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Handle app launch from notification when app was terminated
  Future<void> _handleAppLaunchFromNotification() async {
    // Check if app was opened from a terminated state via notification
    final RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      CustomLogger.logMessage(msg: '🔔 App launched from notification: ${initialMessage.messageId}',level: LogLevel.debug);

      // Wait for app to be ready, then handle navigation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          _handleMessageNavigation(initialMessage);
        });
      });
    }

    // Also listen for when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      CustomLogger.logMessage(msg: '🔔 App opened from background notification: ${message.messageId}',level: LogLevel.debug);
      _handleMessageNavigation(message);
    });
  }

  /// Handle navigation based on message data
  void _handleMessageNavigation(RemoteMessage message) {
    final data = message.data;

    // Payment notifications are handled by NotificationService / SplashController
    final paymentLink = data['paymentLink'] as String? ?? '';
    if (paymentLink.isNotEmpty && paymentLink.contains('pay-share-payment')) {
      return;
    }

    try {
      final notificationUrl = data['notificationUrl'] ?? data['route'] ?? '';
      final redirect = data['redirect'] ?? '';
      final matchId = data['matchId'] ?? '';

      // Get notification controller and use its routing logic
      if (Get.isRegistered<NotificationController>()) {
        final controller = NotificationController.instance;
        
        if (notificationUrl.isNotEmpty) {
          controller.handleNotificationRoute(notificationUrl, redirect: redirect, matchId: matchId);
        } else if (redirect.isNotEmpty) {
          controller.handleNotificationRoute('true', redirect: redirect, matchId: matchId);
        } else {
          Get.toNamed('/notifications');
        }
      } else {
        // Fallback if controller not ready
        Get.toNamed('/notifications');
      }
    } catch (e) {
      CustomLogger.logMessage(msg: '❌ Error navigating from notification: $e',level: LogLevel.error);
      Get.toNamed('/notifications');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        CustomLogger.logMessage(msg: '📱 App resumed',level: LogLevel.debug);
        // Refresh notification controller state if needed
        try {
          final controller = NotificationController.instance;
          controller.refreshToken();
          
          // Also refresh FCM token
          final fcmService = FCMTokenService.instance;
          fcmService.refreshToken();
        } catch (e) {
          CustomLogger.logMessage(msg: '❌ Error refreshing on resume: $e',level: LogLevel.debug);
        }
        break;
      case AppLifecycleState.paused:
        CustomLogger.logMessage(msg: '📱 App paused',level: LogLevel.debug);
        break;
      case AppLifecycleState.detached:
        CustomLogger.logMessage(msg: '📱 App detached',level: LogLevel.debug);
        break;
      case AppLifecycleState.inactive:
        CustomLogger.logMessage(msg: '📱 App inactive',level: LogLevel.debug);
        break;
      case AppLifecycleState.hidden:
        CustomLogger.logMessage(msg: '📱 App hidden',level: LogLevel.debug);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Error app to show when initialization fails
class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('App Initialization Error'),
              const SizedBox(height: 8),
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Restart the app
                  SystemNavigator.pop();
                },
                child: const Text('Restart App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}