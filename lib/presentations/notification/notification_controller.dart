// controllers/notification_controller.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';
import 'package:padel_mobile/data/response_models/get_notification_model.dart';
import 'package:padel_mobile/handler/logger.dart';
import 'package:padel_mobile/presentations/bookinghistory/booking_history_screen.dart';
import 'package:padel_mobile/presentations/profile/profile_controller.dart';
import 'package:padel_mobile/repositories/notification_repo/notification_repository.dart';

import '../../services/notification_service/firebase_notification.dart';
import 'package:flutter/material.dart';
class NotificationController extends GetxController {
  static NotificationController get instance => Get.find();

  final NotificationService _notificationService = NotificationService();
  final GetStorage _storage = GetStorage();

  // Observable variables
  final RxString firebaseToken = ''.obs;
  final RxBool isNotificationEnabled = false.obs;
  final RxBool isInitialized = false.obs;
  final RxList<Map<String, dynamic>> notificationHistory =
      <Map<String, dynamic>>[].obs;
  final RxMap<String, bool> topicSubscriptions = <String, bool>{}.obs;

  // Storage keys
  static const String _tokenKey = 'firebase_token';
  static const String _notificationEnabledKey = 'notification_enabled';
  static const String _historyKey = 'notification_history';
  static const String _topicsKey = 'topic_subscriptions';

  @override
  void onInit()async {
    super.onInit();
   await fetchNotifications();
   await fetchUnreadNotificationCount();
    _loadStoredData();
    _initializeNotifications();
  }

  /// Load stored data
  void _loadStoredData() {
    // Load token
    final storedToken = _storage.read(_tokenKey);
    if (storedToken != null) {
      firebaseToken.value = storedToken;
    }

    // Load notification enabled status
    final enabled = _storage.read(_notificationEnabledKey) ?? false;
    isNotificationEnabled.value = enabled;

    // Load notification history
    final history = _storage.read(_historyKey) ?? [];
    if (history is List) {
      notificationHistory.assignAll(history.cast<Map<String, dynamic>>());
    }

    // Load topic subscriptions
    final topics = _storage.read(_topicsKey) ?? {};
    if (topics is Map) {
      topicSubscriptions.assignAll(topics.cast<String, bool>());
    }
  }

  /// Initialize notification service and request permissions
  Future<void> _initializeNotifications() async {
    try {
      // Initialize the notification service
      final bool initialized = await _notificationService.initialize();

      if (initialized) {
        isInitialized.value = true;
        // Set up callback handlers
        _notificationService.setCallbacks(
          onTapped: _handleNotificationTapped,
          onForeground: _handleForegroundMessage,
          onBackground: _handleBackgroundMessage,
          onTokenRefresh: _handleTokenRefresh,
        );

        // Get and store Firebase token
        await _getAndStoreFirebaseToken();

        // Check notification permission status
        await _checkNotificationPermission();

        // Request permissions after a short delay to ensure Activity is available
        // This handles the case where permissions couldn't be requested during initialization
        Future.delayed(const Duration(seconds: 2), () async {
          try {
            final bool enabled = await _notificationService.areNotificationsEnabled();
            if (!enabled) {
              if (kDebugMode) {
                print('⚠️ Notifications not enabled. Requesting permissions...');
              }
              await requestPermissions();
            }
          } catch (e) {
            if (kDebugMode) {
              print('Could not check/request permissions: $e');
            }
          }
        });

        // Subscribe to stored topics
        await _restoreTopicSubscriptions();

        if (kDebugMode) {
          print('✅ Notification service initialized successfully');
        }
      } else {
        if (kDebugMode) {
          print('❌Failed to initialize notification service');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌Error initializing notifications: $e');
      }
    }
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    if (!isInitialized.value) {
      if (kDebugMode) {
        print('⚠️ Notification service not initialized');
      }
      return false;
    }

    try {
      // Use the service's requestPermissions method which handles both Android and iOS
      final bool granted = await _notificationService.requestPermissions();
      
      isNotificationEnabled.value = granted;
      await _storage.write(_notificationEnabledKey, granted);

      if (granted) {
        await _getAndStoreFirebaseToken();
        if (kDebugMode) {
          print('✅ Notification permissions granted');
        }
      } else {
        if (kDebugMode) {
          print('❌ Notification permissions denied');
        }
      }

      return granted;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error requesting permissions: $e');
      }
      return false;
    }
  }

  /// Get and store Firebase token
  Future<void> _getAndStoreFirebaseToken() async {
    try {
      final String? token = await _notificationService.getFirebaseToken();

      if (token != null && token.isNotEmpty) {
        firebaseToken.value = token;
        await _storage.write(_tokenKey, token);
        await _sendTokenToServer(token);
        if (kDebugMode) {
          print('✅ Firebase token retrieved: ${token.substring(0, 20)}...');
        }
      } else {
        if (kDebugMode) {
          print('❌ Failed to get Firebase token');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting Firebase token: $e');
      }
    }
  }

  /// Check current notification permission status
  Future<void> _checkNotificationPermission() async {
    try {
      final bool enabled = await _notificationService.areNotificationsEnabled();
      isNotificationEnabled.value = enabled;
      await _storage.write(_notificationEnabledKey, enabled);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking notification permission: $e');
      }
    }
  }
  /// Restore topic subscriptions from storage
  Future<void> _restoreTopicSubscriptions() async {
    try {
      for (final entry in topicSubscriptions.entries) {
        if (entry.value) {
          await _notificationService.subscribeToTopic(entry.key);
        }
      }
      if (kDebugMode) {
        print('✅ Restored topic subscriptions');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error restoring topic subscriptions: $e');
      }
    }

  }

  /// Send token to server
  Future<void> _sendTokenToServer(String token) async {
    try {
      if (kDebugMode) {
        print('📤 Token should be sent to server: $token');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending token to server: $e');
      }
    }
  }
  /// Handle notification tap
  void _handleNotificationTapped(String payload) {
    if (kDebugMode) {
      print('🔔 Notification tapped with payload: $payload');
    }

    try {
      if (payload.isNotEmpty) {
        if (payload.contains('creatematch')) {
          Get.toNamed('/creatematch-details');
        } else if (payload.contains('booking')) {
          Get.toNamed('/booking-details');
        } else {
          Get.toNamed('/notifications');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling notification tap: $e');
      }
    }
  }

  /// Handle notification URL routing
  void handleNotificationRoute(String notificationUrl, {String? redirect, String? matchId}) {
    if (kDebugMode) {
      print('🔔 Handling notification URL: $notificationUrl, redirect: $redirect, matchId: $matchId');
    }

    try {
      if (notificationUrl == 'true') {
        if (redirect != null && redirect.isNotEmpty) {
          if (redirect == '/openmatchrequest') {
            Get.toNamed(RoutesName.requests);
          } else {
            Get.toNamed(redirect);
          }
        }
        return;
      }

      switch (notificationUrl) {
        case '/yourMatchRequest':
          Get.toNamed(RoutesName.requests);
          break;
        case "/bookingRequests":
          Get.toNamed(RoutesName.requests);
          break;
        case '/matches':
          Get.to(BookingHistoryUi(buttonType: "drawer",));
          break;
        case '/matchmessage':
          Get.toNamed(RoutesName.chat, arguments: {
            "matchID": matchId ?? "",
          });
        case '/simpleBooking':
          Get.to(BookingHistoryUi(buttonType: "drawer",));
        default:
          if (kDebugMode) {
            print('⚠️ Unknown notification URL: $notificationUrl');
          }
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling notification route: $e');
      }
    }
  }


  final ProfileController profileController = Get.put(ProfileController());
  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) async{
    if (kDebugMode) {
      print('🔔 Foreground message: ${message.notification?.title}');
    }

    // Add to history
    _addToHistory(message);

    if (message.notification != null) {
      await fetchUnreadNotificationCount();
      await fetchNotifications();
      await profileController.fetCustomerLeaderBoardRank();
      CustomLogger.logMessage(
          msg: "${message.notification!.title ?? 'New Message'}\n"
          "${message.notification!.body ?? ''}",
          level: LogLevel.info);
    }
  }

  /// Handle background messages
  void _handleBackgroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('🔔 Background message: ${message.notification?.title}');
    }
    _addToHistory(message);
    _processMessageData(message.data);
  }

  /// Add notification to history
  void _addToHistory(RemoteMessage message) {
    final notification = {
      'title': message.notification?.title ?? 'No title',
      'body': message.notification?.body ?? 'No body',
      'timestamp': DateTime.now().toString(),
      'data': message.data,
    };

    notificationHistory.insert(0, notification);
    // Keep only last 50 notifications
    if (notificationHistory.length > 50) {
      notificationHistory.removeRange(50, notificationHistory.length);
    }

    _storage.write(_historyKey, notificationHistory.toList());
  }

  /// Process message data
  void _processMessageData(Map<String, dynamic> data) {
    final String? type = data['type'];
    switch (type) {
      case 'match_invitation':
        break;
      case 'booking_confirmation':
        break;
      case 'payment_success':
        break;
      default:
        if (kDebugMode) {
          print('Unknown notification type: $type');
        }
    }
  }

  /// Show local notification manually
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    bool highPriority = true,
  }) async {
    if (!isInitialized.value) return;

    await _notificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      payload: payload,
      highPriority: highPriority,
    );

    // Add to history
    _addToHistory(
      RemoteMessage(
        messageId: DateTime.now().toString(),
        notification: RemoteNotification(title: title, body: body),
        data: {'type': 'local', 'payload': payload ?? ''},
      ),
    );
  }

  /// Schedule a notification
  Future<void> scheduleNotification({

    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    if (!isInitialized.value) return;

    await _notificationService.showScheduledNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      payload: payload,
    );
  }


  /// Subscribe to a topic
  Future<bool> subscribeToTopic(String topic) async {
    final success = await _notificationService.subscribeToTopic(topic);
    if (success) {
      topicSubscriptions[topic] = true;
      await _storage.write(_topicsKey, topicSubscriptions);
    }
    return success;
  }

  /// Unsubscribe from a topic
  Future<bool> unsubscribeFromTopic(String topic) async {
    final success = await _notificationService.unsubscribeFromTopic(topic);
    if (success) {
      topicSubscriptions[topic] = false;
      await _storage.write(_topicsKey, topicSubscriptions);
    }
    return success;
  }

  /// Check if subscribed to topic
  bool isSubscribedToTopic(String topic) {
    return topicSubscriptions[topic] ?? false;
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationService.cancelAllNotifications();
  }

  /// Clear notification history
  void clearNotificationHistory() {
    notificationHistory.clear();
    _storage.remove(_historyKey);
  }

  /// Get stored token
  String? getStoredToken() {
    return _storage.read(_tokenKey);
  }

  /// Check if notifications are enabled
  bool get areNotificationsEnabled => isNotificationEnabled.value;

  /// Refresh token
  Future<void> refreshToken() async {
    await _getAndStoreFirebaseToken();
  }

  /// Test local notification (for debugging)
  Future<bool> testLocalNotification() async {
    if (!isInitialized.value) {
      if (kDebugMode) {
        print('⚠️ Notification service not initialized');
      }
      return false;
    }

    try {
      final bool result = await _notificationService.testLocalNotification();
      if (kDebugMode) {
        print(result 
            ? '✅ Test notification sent successfully' 
            : '❌ Failed to send test notification');
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error testing local notification: $e');
      }
      return false;
    }
  }

  /// Handle token refresh
  void _handleTokenRefresh(String newToken) {
    if (kDebugMode) {
      print('🔄 Token refreshed: ${newToken.substring(0, 20)}...');
    }
    firebaseToken.value = newToken;
    _storage.write('firebase_token', newToken);
    _sendTokenToServer(newToken);
  }

  /// Generate initials from name
  String getInitials(String name) {
    if (name.isEmpty) return 'U';

    // Remove extra whitespace and split by space
    final words = name.trim().split(RegExp(r'\s+'));

    if (words.isEmpty) return 'U';

    if (words.length == 1) {
      // Single word: return first character in uppercase
      return words[0][0].toUpperCase();
    }

    // Multiple words: return first character of first two words in uppercase
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }
  String capitalizeWords(String text) {
    if (text.isEmpty) return text;

    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  void onClose() {
    _notificationService.dispose();
    super.onClose();
  }

  /// Get Notification Api------------------------------------------------------
  final RxList<Map<String, dynamic>> notifications =
      <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;
  final NotificationRepository notificationRepository = Get.put(
    NotificationRepository(),
  );
  var notificationList = <GetNotificationResponse>[].obs;

  Future<void> fetchNotifications() async {
    notifications.clear();
    isLoading.value = true;

    try {
      final response = await notificationRepository.getNotification();
      final apiNotifications = response.notifications ?? [];
      if (apiNotifications.isNotEmpty) {
        notifications.assignAll(
          apiNotifications.map((notif) {
            IconData icon;
            final type = (notif.notificationType ?? '').toLowerCase();
            if (type.contains('booking')) {
              icon = Icons.check_circle;
            } else if (type.contains('payment')) {
              icon = Icons.payment;
            } else if (type.contains('offer')) {
              icon = Icons.local_offer;
            } else {
              icon = Icons.notifications;
            }

            final createdAt = notif.createdAt != null
                ? DateTime.tryParse(notif.createdAt!)
                : DateTime.now();

            return {
              'id': notif.id ?? '',
              'title': notif.title ?? 'No Title',
              'message': notif.message ?? 'No Message',
              'time': createdAt,
              'icon': icon,
              'payload': notif.notificationUrl ?? '',
              'redirect': notif.redirect ?? '',
              'bookingId': notif.bookingId?.id ?? '',
              'matchId': notif.matchId ?? '',
              'isRead': notif.isRead ?? false,
              'bookingStatus': notif.bookingId?.bookingStatus ?? '',
              'notificationType': notif.notificationType ?? '',
              'profileImage': notif.profileImage ?? '',
              'userName': notif.title ?? 'User',
            };
          }).toList(),
        );

      }
    } catch (e) {
      CustomLogger.logMessage(
        msg: "Error fetching Notification: $e",
        level: LogLevel.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Mark a single notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await notificationRepository.markAsRead(notificationId);
      // Update local state
      final index = notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        notifications[index]['isRead'] = true;
        notifications.refresh();
        fetchUnreadNotificationCount();
      }
    } catch (e) {
      CustomLogger.logMessage(
        msg: "❌ Error marking notification as read: $e",
        level: LogLevel.error,
      );
    }
  }

  /// Mark all as read
  Future<void> markAllNotificationsAsRead() async {
    try {
      await notificationRepository.markAllAsRead();
      for (var n in notifications) {
        n['isRead'] = true;
      }
      notifications.refresh();
      fetchUnreadNotificationCount();
    } catch (e) {
      CustomLogger.logMessage(
        msg: "❌ Error marking all notifications as read: $e",
        level: LogLevel.error,
      );
    }
  }

  /// Get Unread Notification Count API ------------------------------------------------------
  var unreadNotificationCount = 0.obs;

  Future<void> fetchUnreadNotificationCount() async {
    try {
      final now = DateTime.now();
      CustomLogger.logMessage(
        msg: '📡 Fetching unread count at: $now',
        level: LogLevel.info,
      );

      final response = await notificationRepository.notificationCount();

      final count = response['unreadCount'] ?? 0;
      CustomLogger.logMessage(
        msg: '✅ API responded with unreadCount=$count at ${DateTime.now()}',
        level: LogLevel.info,
      );

      unreadNotificationCount.value = count;
    } catch (e) {
      CustomLogger.logMessage(
        msg: '❌ Error fetching unread count: $e',
        level: LogLevel.error,
      );
    }
  }

}
