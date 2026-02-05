import 'dart:developer';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

/// Professional notification service handling both local and Firebase notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  // Notification channels
  static const String _channelId = 'default_channel';
  static const String _channelName = 'Default Notifications';
  static const String _channelDescription = 'Default notification channel';

  static const String _highPriorityChannelId = 'high_priority_channel';
  static const String _highPriorityChannelName = 'High Priority Notifications';
  static const String _highPriorityChannelDescription =
      'High priority notification channel';

  // Plugin instances
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Notification callback handlers
  Function(String)? onNotificationTapped;
  Function(RemoteMessage)? onForegroundMessage;
  Function(RemoteMessage)? onBackgroundMessage;
  Function(String)? onTokenRefresh;

  bool _isInitialized = false;

  /// Initialize the notification service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Initialize local notifications
      await _initializeLocalNotifications();

      // Initialize Firebase messaging
      await _initializeFirebaseMessaging();

      // Request permissions (non-blocking - don't fail initialization if this fails)
      // Permissions will be requested when actually showing notifications
      _requestPermissions().catchError((e) {
        log('Permission request failed during initialization (non-critical): $e');
        return false; // Return false to indicate failure, but don't block initialization
      });

      _isInitialized = true;
      log('NotificationService initialized successfully');
      return true;
    } catch (e) {
      log('Failed to initialize NotificationService: $e');
      return false;
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@drawable/ic_padel_notification');

    // Request permissions on iOS during initialization
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    final bool? initialized = await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (initialized == true) {
      log('Local notifications initialized successfully');
    } else {
      log('Local notifications initialization returned: $initialized');
    }

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      // Delete existing channels first (if they exist) to recreate with new settings
      // Note: Android doesn't allow changing channel importance after creation
      try {
        await androidImplementation.deleteNotificationChannel(_channelId);
        await androidImplementation.deleteNotificationChannel(_highPriorityChannelId);
        log('Deleted existing notification channels to recreate with new settings');
      } catch (e) {
        log('Could not delete notification channels (may not exist): $e');
      }

      // Default channel - using max importance to ensure notifications show
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.max, // Use max for better visibility
          playSound: true,
          enableVibration: true,
          showBadge: true, // Show badge on app icon
        ),
      );
      log('Created notification channel: $_channelId with max importance');

      // High priority channel
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          _highPriorityChannelId,
          _highPriorityChannelName,
          description: _highPriorityChannelDescription,
          importance: Importance.max, // Use max for better visibility
          playSound: true,
          enableVibration: true,
          showBadge: true, // Show badge on app icon
        ),
      );
      log('Created notification channel: $_highPriorityChannelId with max importance');
    }
  }

  /// Initialize Firebase messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages (when app is in background but not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Handle messages when app is opened from terminated state
    final RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessage(initialMessage);
    }

    // Listen for token refresh (important for Android)
    _firebaseMessaging.onTokenRefresh.listen((String newToken) {
      log('Firebase token refreshed: ${newToken.substring(0, 20)}...');
      onTokenRefresh?.call(newToken);
    });
  }

  /// Handle foreground Firebase messages
  void _handleForegroundMessage(RemoteMessage message) {
    log('Received foreground message: ${message.messageId}');

    // Show local notification for foreground messages with high priority
    showNotification(
      id: message.hashCode,
      title: message.notification?.title ?? 'New Message',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
      highPriority: true, // Use high priority for foreground messages
    );

    onForegroundMessage?.call(message);
  }

  /// Handle background Firebase messages
  void _handleBackgroundMessage(RemoteMessage message) {
    log('Handling background message: ${message.messageId}');
    onBackgroundMessage?.call(message);
  }

  /// Handle local notification taps
  void _onNotificationTapped(NotificationResponse response) {
    log('Notification tapped with payload: ${response.payload}');
    onNotificationTapped?.call(response.payload ?? '');
  }

  /// Request necessary permissions (public method - can be called when Activity is available)
  Future<bool> requestPermissions() async {
    return await _requestPermissions();
  }

  /// Request necessary permissions (internal method)
  Future<bool> _requestPermissions() async {
    bool allGranted = true;

    // Request notification permission (Android 13+)
    // Note: This requires Activity context, so it may fail during early initialization
    if (Platform.isAndroid) {
      try {
        final notificationStatus = await Permission.notification.request();
        if (!notificationStatus.isGranted) {
          log('Android notification permission denied');
          allGranted = false;
        } else {
          log('Android notification permission granted');
        }
      } catch (e) {
        // Activity may not be available during initialization
        log('Could not request Android notification permission (Activity not available): $e');
        // Don't fail initialization - permissions can be requested later
        allGranted = false;
      }
    }

    // Request Firebase messaging permission (iOS and Android)
    try {
      final NotificationSettings firebaseSettings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );

      if (firebaseSettings.authorizationStatus !=
          AuthorizationStatus.authorized &&
          firebaseSettings.authorizationStatus !=
          AuthorizationStatus.provisional) {
        log('Firebase messaging permission denied. Status: ${firebaseSettings.authorizationStatus}');
        allGranted = false;
      } else {
        log('Firebase messaging permission granted. Status: ${firebaseSettings.authorizationStatus}');
      }
    } catch (e) {
      log('Could not request Firebase messaging permission: $e');
      allGranted = false;
    }

    return allGranted;
  }

  /// Show a simple notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool highPriority = false,
  }) async {
    if (!_isInitialized) {
      log('NotificationService not initialized. Attempting to initialize...');
      final initialized = await initialize();
      if (!initialized) {
        log('Failed to initialize NotificationService');
        return;
      }
    }

    // Check if notifications are enabled before showing
    if (Platform.isAndroid) {
      try {
        final bool enabled = await areNotificationsEnabled();
        if (!enabled) {
          log('Notifications are not enabled on Android. Requesting permission...');
          try {
            final bool granted = await _requestPermissions();
            if (!granted) {
              log('Notification permission denied. Attempting to show notification anyway...');
              // Continue anyway - some devices may still show notifications
            }
          } catch (e) {
            log('Could not request permissions (Activity may not be available): $e');
            // Continue anyway - try to show notification
          }
        }
      } catch (e) {
        log('Could not check notification permissions: $e. Attempting to show notification anyway...');
        // Continue anyway - try to show notification
      }
    }

    final String channelId = highPriority ? _highPriorityChannelId : _channelId;

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          channelId,
          highPriority ? _highPriorityChannelName : _channelName,
          channelDescription: highPriority
              ? _highPriorityChannelDescription
              : _channelDescription,
          importance: Importance.max, // Use max importance to ensure visibility
          priority: Priority.max, // Use max priority
          showWhen: true,
          when: DateTime.now().millisecondsSinceEpoch,
          playSound: true,
          enableVibration: true,
          icon: '@drawable/ic_padel_notification',
          autoCancel: true, // Auto-dismiss when tapped
          ongoing: false, // Not ongoing notification
          visibility: NotificationVisibility.public, // Show on lock screen
          showProgress: false,
          ticker: title, // Show ticker text
          styleInformation: const DefaultStyleInformation(true, true), // Use default style
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    try {
      // Ensure we're using a positive notification ID
      final int notificationId = id.isNegative ? id.abs() : id;
      
      await _localNotifications.show(notificationId, title, body, details, payload: payload);
      log('Local notification shown successfully: id=$notificationId, title=$title, body=$body');
      
      // Verify notification was actually shown (Android specific)
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        if (androidImplementation != null) {
          final bool? enabled = await androidImplementation.areNotificationsEnabled();
          log('Android notifications enabled status: $enabled');
        }
      }
    } catch (e, stackTrace) {
      log('Failed to show local notification: $e');
      log('Stack trace: $stackTrace');
    }
  }

  /// Show a scheduled notification
  Future<void> showScheduledNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    bool highPriority = true,
  }) async {
    if (!_isInitialized) {
      log('NotificationService not initialized');
      return;
    }

    final tz.TZDateTime scheduledTZTime = tz.TZDateTime.from(
      scheduledTime,
      tz.local,
    );

    final String channelId = highPriority ? _highPriorityChannelId : _channelId;
    final Importance importance = highPriority
        ? Importance.high
        : Importance.defaultImportance;
    final Priority priority = highPriority
        ? Priority.high
        : Priority.defaultPriority;

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          channelId,
          highPriority ? _highPriorityChannelName : _channelName,
          channelDescription: highPriority
              ? _highPriorityChannelDescription
              : _channelDescription,
          importance: importance,
          priority: priority,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      scheduledTZTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Get Firebase messaging token with retry logic
  Future<String?> getFirebaseToken({int maxRetries = 3, Duration delay = const Duration(seconds: 2)}) async {
    if (!_isInitialized) {
      log('NotificationService not initialized. Initializing now...');
      final initialized = await initialize();
      if (!initialized) {
        log('Failed to initialize NotificationService');
        return null;
      }
    }

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // Check if permissions are granted (especially important for Android 13+)
        if (Platform.isAndroid) {
          final NotificationSettings settings = await _firebaseMessaging.getNotificationSettings();
          if (settings.authorizationStatus != AuthorizationStatus.authorized &&
              settings.authorizationStatus != AuthorizationStatus.provisional) {
            log('Notification permissions not granted. Requesting permissions...');
            final NotificationSettings newSettings = await _firebaseMessaging.requestPermission(
              alert: true,
              badge: true,
              sound: true,
              provisional: false,
            );
            
            if (newSettings.authorizationStatus != AuthorizationStatus.authorized &&
                newSettings.authorizationStatus != AuthorizationStatus.provisional) {
              log('Notification permissions denied. Cannot get token.');
              return null;
            }
          }
        }

        // Get the token
        final String? token = await _firebaseMessaging.getToken();
        
        if (token != null && token.isNotEmpty) {
          log('Successfully retrieved Firebase token (attempt $attempt)');
          return token;
        } else {
          log('Token is null or empty (attempt $attempt/$maxRetries)');
        }
      } catch (e) {
        log('Failed to get Firebase token (attempt $attempt/$maxRetries): $e');
        
        // If it's the last attempt, return null
        if (attempt == maxRetries) {
          log('Max retries reached. Failed to get Firebase token.');
          return null;
        }
      }

      // Wait before retrying (except on last attempt)
      if (attempt < maxRetries) {
        log('Retrying token retrieval in ${delay.inSeconds} seconds...');
        await Future.delayed(delay);
      }
    }

    return null;
  }

  /// Subscribe to a Firebase topic
  Future<bool> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      log('Subscribed to topic: $topic');
      return true;
    } catch (e) {
      log('Failed to subscribe to topic $topic: $e');
      return false;
    }
  }

  /// Unsubscribe from a Firebase topic
  Future<bool> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      log('Unsubscribed from topic: $topic');
      return true;
    } catch (e) {
      log('Failed to unsubscribe from topic $topic: $e');
      return false;
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _localNotifications.pendingNotificationRequests();
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _localNotifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      final bool? enabled = await androidImplementation?.areNotificationsEnabled();
      log('Android notifications enabled: $enabled');
      return enabled ?? false;
    } else if (Platform.isIOS) {
      // For iOS, check Firebase messaging permission status
      final NotificationSettings settings = await _firebaseMessaging.getNotificationSettings();
      final bool enabled = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      log('iOS notifications enabled: $enabled (status: ${settings.authorizationStatus})');
      return enabled;
    }
    return true; // Default for other platforms
  }

  /// Set notification callback handlers
  void setCallbacks({
    Function(String)? onTapped,
    Function(RemoteMessage)? onForeground,
    Function(RemoteMessage)? onBackground,
    Function(String)? onTokenRefresh,
  }) {
    onNotificationTapped = onTapped;
    onForegroundMessage = onForeground;
    onBackgroundMessage = onBackground;
    this.onTokenRefresh = onTokenRefresh;
  }

  /// Test local notification (useful for debugging)
  Future<bool> testLocalNotification() async {
    try {
      await showNotification(
        id: 999999,
        title: 'Test Notification',
        body: 'This is a test local notification. If you see this, local notifications are working!',
        payload: 'test',
        highPriority: true,
      );
      log('Test notification sent successfully');
      return true;
    } catch (e) {
      log('Failed to send test notification: $e');
      return false;
    }
  }

  /// Dispose resources (call this when app is being destroyed)
  void dispose() {
    _isInitialized = false;
    onNotificationTapped = null;
    onForegroundMessage = null;
    onBackgroundMessage = null;
    onTokenRefresh = null;
  }
}
