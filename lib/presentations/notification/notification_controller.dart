// controllers/notification_controller.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';
import 'package:padel_mobile/data/response_models/get_notification_model.dart';
import 'package:padel_mobile/handler/logger.dart';
import 'package:padel_mobile/presentations/bookinghistory/booking_history_screen.dart';
import 'package:padel_mobile/presentations/profile/profile_controller.dart';
import 'package:padel_mobile/repositories/notification_repo/notification_repository.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../services/notification_service/firebase_notification.dart';
import 'package:flutter/material.dart';
import '../../configs/components/app_toast.dart';
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
    _setupIOSNotificationChannel();
  }

  /// Setup iOS notification channel listener
  void _setupIOSNotificationChannel() {
    if (GetPlatform.isIOS) {
      const platform = MethodChannel('notification_tap_channel');
      platform.setMethodCallHandler((call) async {
        if (call.method == 'onNotificationTap') {
          final String payload = call.arguments as String? ?? '';
          if (kDebugMode) {
            print('🍎 iOS Notification tap received via method channel');
            print('🍎 Payload: $payload');
          }
          _handleNotificationTapped(payload);
        }
      });
      if (kDebugMode) {
        print('✅ iOS notification channel listener setup complete');
      }
    }
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
      if (payload.isEmpty) {
        Get.toNamed(RoutesName.notification);
        return;
      }

      // Parse payload format: key1=value1|key2=value2
      final Map<String, String> data = {};
      if (payload.contains('|')) {
        final parts = payload.split('|');
        for (var part in parts) {
          if (part.contains('=')) {
            final kv = part.split('=');
            if (kv.length == 2) {
              // Skip aps object (iOS specific)
              if (!kv[0].startsWith('aps')) {
                data[kv[0]] = kv[1];
              }
            }
          }
        }
      }

      if (kDebugMode) {
        print('🔔 Parsed data: $data');
      }

      // Extract routing info
      final notificationUrl = data['notificationUrl'] ?? data['route'] ?? '';
      final redirect = data['redirect'] ?? '';
      final matchId = data['matchId'] ?? '';
      final type = data['type'] ?? '';
      final bookingId = data['bookingId'] ?? '';
      final action = data['action'] ?? '';
      final paymentLink = data['paymentLink'] ?? '';
      final paymentHistoryId = data['paymentHistoryId'] ?? '';

      // Priority 1: Check for payment link action
      if (action == 'open_payment_popup' && paymentLink.isNotEmpty) {
        _navigateToSharePayment(paymentLink, paymentHistoryId: paymentHistoryId);
        return;
      }

      // Also handle payment link without explicit action field
      if (paymentLink.isNotEmpty && paymentLink.contains('pay-share-payment')) {
        _navigateToSharePayment(paymentLink, paymentHistoryId: paymentHistoryId);
        return;
      }

      // Priority 2: Use notificationUrl if present
      if (notificationUrl.isNotEmpty) {
        handleNotificationRoute(notificationUrl, redirect: redirect, matchId: matchId);
        return;
      }

      // Priority 3: Use redirect if present
      if (redirect.isNotEmpty) {
        handleNotificationRoute('true', redirect: redirect, matchId: matchId);
        return;
      }

      // Priority 4: Use type-based routing
      if (type.isNotEmpty) {
        _handleNotificationByType(type, bookingId: bookingId, matchId: matchId);
        return;
      }

      // Fallback: Go to notification list
      Get.toNamed(RoutesName.notification);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error handling notification tap: $e');
        print('Stack trace: $stackTrace');
      }
      Get.toNamed(RoutesName.notification);
    }
  }

  /// Navigate to the SharePayment screen for a notification payment link
  void _navigateToSharePayment(String paymentLink, {String? paymentHistoryId}) {
    try {
      // Prefer the explicit paymentHistoryId from notification data,
      // then fall back to extracting from the URL path
      String paymentId = paymentHistoryId ?? '';
      if (paymentId.isEmpty) {
        paymentId = _extractPaymentId(paymentLink);
      }
      if (paymentId.isEmpty) {
        // Last resort: grab the last path segment of the URL
        final uri = Uri.tryParse(paymentLink);
        paymentId = uri?.pathSegments.lastWhere((s) => s.isNotEmpty, orElse: () => '') ?? '';
      }
      if (paymentId.isEmpty) {
        CustomLogger.logMessage(msg: '❌ Could not extract paymentId from: $paymentLink', level: LogLevel.error);
        return;
      }
      final token = GetStorage().read<String>('token') ?? '';
      // Delay to ensure the navigator is fully ready after app resume
      Future.delayed(const Duration(milliseconds: 500), () {
        if (token.isNotEmpty) {
          Get.toNamed(RoutesName.sharePayment, arguments: {'paymentId': paymentId});
        } else {
          GetStorage().write('pendingPaymentId', paymentId);
          Get.offAllNamed(RoutesName.login);
        }
      });
      CustomLogger.logMessage(msg: '✅ Navigating to sharePayment: $paymentId', level: LogLevel.debug);
    } catch (e) {
      CustomLogger.logMessage(msg: '❌ Error navigating to sharePayment: $e', level: LogLevel.error);
    }
  }

  /// Open payment link popup with notification data
  void _openPaymentLinkWithData(String paymentLink, Map<String, String> notificationData) {
    try {
      final paymentId = _extractPaymentId(paymentLink);
      _showPaymentDialog(paymentId, notificationData);
      
      if (kDebugMode) {
        print('✅ Opened payment popup for ID: $paymentId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error opening payment popup: $e');
      }
    }
  }

  /// Open payment link popup (legacy support)
  void _openPaymentLink(String paymentLink) {
    _openPaymentLinkWithData(paymentLink, {});
  }

  /// Show payment dialog with data
  void _showPaymentDialog(String paymentId, Map<String, String> notificationData) {
    final totalAmount = notificationData['amount'] ?? '0.00';
    final walletAmount = notificationData['walletContributionAmount'] ?? '0';
    final razorpayAmount = notificationData['razorpayAmountDue'] ?? '0';
    final clubName = notificationData['clubName'] ?? 'Club';
    final courtName = notificationData['courtName'] ?? '';
    final dateTime = notificationData['dateTime'] ?? '';
    final paymentMode = notificationData['paymentMode'] ?? 'wallet';
    final paymentLink = notificationData['paymentLink'] ?? '';
    final isWalletPayment = paymentMode.toLowerCase() == 'wallet';
    final isSplitPayment = paymentMode.toLowerCase() == 'split';
    
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.account_balance_wallet,
                size: 64,
                color: Color(0xFF1E40AF),
              ),
              const SizedBox(height: 16),
              Text(
                "Payment Request",
                style: Get.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    if (clubName.isNotEmpty) ...[
                      _buildInfoRow(Icons.location_on, 'Club', clubName),
                      const SizedBox(height: 12),
                    ],
                    if (courtName.isNotEmpty) ...[
                      _buildInfoRow(Icons.sports_tennis, 'Court', courtName),
                      const SizedBox(height: 12),
                    ],
                    if (dateTime.isNotEmpty) ...[
                      _buildInfoRow(Icons.calendar_today, 'Date & Time', dateTime),
                      const SizedBox(height: 12),
                    ],
                    Divider(color: Colors.grey.shade300, height: 1),
                    const SizedBox(height: 12),
                    // Total Amount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount',
                          style: Get.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '₹$totalAmount',
                          style: Get.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    // Split Payment Details
                    if (isSplitPayment && walletAmount != '0') ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.account_balance_wallet, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                'From Wallet',
                                style: Get.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '₹$walletAmount',
                            style: Get.textTheme.bodyMedium?.copyWith(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (isSplitPayment && razorpayAmount != '0') ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.payment, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                'To Pay Now',
                                style: Get.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '₹$razorpayAmount',
                            style: Get.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF1E40AF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Do you want to proceed with this payment?",
                textAlign: TextAlign.center,
                style: Get.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        if (isWalletPayment) {
                          _handlePaymentSubmit(paymentId);
                        } else {
                          _openPaymentUrl(paymentLink);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E40AF),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Confirm Payment",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Build info row widget
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Extract payment ID from link
  String _extractPaymentId(String paymentLink) {
    final uri = Uri.parse(paymentLink);
    final segments = uri.pathSegments;
    final index = segments.indexOf('pay-share-payment');
    if (index != -1 && index + 1 < segments.length) {
      return segments[index + 1];
    }
    return '';
  }

  /// Handle payment submission
  Future<void> _handlePaymentSubmit(String paymentId) async {
    try {
      AppToast.info("Processing payment...");
      
      final response = await notificationRepository.acceptWalletPayment(paymentId);
      
      AppToast.success("Payment completed successfully!");
      
      // Refresh notifications after payment
      await fetchNotifications();
      await fetchUnreadNotificationCount();
    } catch (e) {
      AppToast.error("Payment failed. Please try again.");
      if (kDebugMode) {
        print('❌ Payment error: $e');
      }
    }
  }

  /// Open payment URL in in-app WebView dialog
  Future<void> _openPaymentUrl(String url) async {
    try {
      if (url.isEmpty) {
        AppToast.error("Payment link not available");
        return;
      }

      Get.dialog(
        Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: Get.height * 0.85,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Complete Payment',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            Get.back();
                            // Refresh notifications when closing
                            fetchNotifications();
                            fetchUnreadNotificationCount();
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: _PaymentWebView(url: url)),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );
      
      if (kDebugMode) {
        print('✅ Opened payment URL in WebView: $url');
      }
    } catch (e) {
      AppToast.error("Failed to open payment link");
      if (kDebugMode) {
        print('❌ Error opening payment URL: $e');
      }
    }
  }

  /// Handle notification by type
  void _handleNotificationByType(String type, {String? bookingId, String? matchId}) {
    if (kDebugMode) {
      print('🔔 Handling notification by type: $type, bookingId: $bookingId, matchId: $matchId');
    }

    switch (type.toLowerCase()) {
      case 'booking_invitation':
      case 'booking_confirmation':
      case 'booking_accepted':
      case 'booking_rejected':
      case 'booking_cancelled':
        Get.to(() => BookingHistoryUi(buttonType: "drawer"));
        break;
      
      case 'match_invitation':
      case 'match_request':
      case 'match_accepted':
      case 'match_rejected':
        Get.toNamed(RoutesName.requests);
        break;
      
      case 'match_message':
      case 'chat_message':
        if (matchId != null && matchId.isNotEmpty) {
          Get.toNamed(RoutesName.chat, arguments: {"matchID": matchId});
        } else {
          Get.toNamed(RoutesName.notification);
        }
        break;
      
      case 'league_invitation':
      case 'league_update':
        Get.toNamed(RoutesName.notification);
        break;
      
      default:
        if (kDebugMode) {
          print('⚠️ Unknown notification type: $type');
        }
        Get.toNamed(RoutesName.notification);
        break;
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

      if (notificationUrl.startsWith('/league/')) {
        final leagueId = notificationUrl.split('/league/').last;
        Get.toNamed(RoutesName.league, arguments: {
          'leagueId': leagueId,
        });
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
          break;
        case '/simpleBooking':
          Get.to(BookingHistoryUi(buttonType: "drawer",));
          break;
        case '/Scoreboard':
          Get.to(BookingHistoryUi(buttonType: "drawer",));
          break;
        case '/user/bookings':
          Get.to(BookingHistoryUi(buttonType: "drawer",));
          break;
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




/// WebView widget for payment popup
class _PaymentWebView extends StatefulWidget {
  final String url;

  const _PaymentWebView({required this.url});

  @override
  State<_PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<_PaymentWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) => setState(() => _isLoading = true),
          onPageFinished: (url) => setState(() => _isLoading = false),
          onNavigationRequest: (request) {
            if (request.url.contains('success') || 
                request.url.contains('payment_success') ||
                request.url.contains('payment-success')) {
              Get.back();
              AppToast.success('Payment completed successfully!');
              final controller = Get.find<NotificationController>();
              controller.fetchNotifications();
              controller.fetchUnreadNotificationCount();
              return NavigationDecision.prevent;
            }
            if (request.url.contains('failure') || 
                request.url.contains('payment_failure') ||
                request.url.contains('payment-failure')) {
              Get.back();
              AppToast.error('Payment failed. Please try again.');
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF1E40AF),
            ),
          ),
      ],
    );
  }
}
