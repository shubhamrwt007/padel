
import 'package:padel_mobile/core/endpoitns.dart';
import 'package:padel_mobile/core/network/dio_client.dart';
import 'package:padel_mobile/data/response_models/get_notification_model.dart';
import 'package:padel_mobile/handler/logger.dart';

class NotificationRepository {
  static final NotificationRepository _instance = NotificationRepository
      ._internal();
  final DioClient dioClient = DioClient();

  factory NotificationRepository() {
    return _instance;
  }

  NotificationRepository._internal();

  ///Get Notification-----------------------------------------------------------
  Future<GetNotificationModel> getNotification() async {
    try {
      final response = await dioClient.get(
        AppEndpoints.getNotification,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Get-Notification Data: ${response.data}",
          level: LogLevel.info,
        );
        return GetNotificationModel.fromJson(response.data);
      } else {
        throw Exception("Get-Notification failed: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Get-Notification failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }

  ///Mark As Read Notification--------------------------------------------------
  Future<void> markAsRead(String notificationId) async {
    try {
      final response = await dioClient.get(
        "${AppEndpoints.getNotificationMarkAsRead}?id=$notificationId",
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "✅ Notification marked as read: $notificationId",
          level: LogLevel.info,
        );
      } else {
        throw Exception("Failed to mark as read: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "❌ markAsRead failed: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }

  ///Mark All As Read Notification----------------------------------------------
  Future<void> markAllAsRead() async {
    try {
      final response = await dioClient.get(
        AppEndpoints.getNotificationMarkAsReadALl,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "✅ All notifications marked as read",
          level: LogLevel.info,
        );
      } else {
        throw Exception("Failed to mark all as read: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "❌ markAllAsRead failed: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }

  ///Notification Count---------------------------------------------------------
  Future<Map<String, dynamic>> notificationCount() async {
    try {
      final response = await dioClient.get(AppEndpoints.getNotificationCount);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        CustomLogger.logMessage(
          msg: "✅ Unread count fetched successfully: ${data['unreadCount']}",
          level: LogLevel.info,
        );

        return data;
      } else {
        throw Exception("❌ Failed to fetch unread count: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "❌ notificationCount failed: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }

  ///Accept Wallet Payment-----------------------------------------------------
  Future<Map<String, dynamic>> acceptWalletPayment(String paymentId) async {
    try {
      final String endpoint = "${AppEndpoints.baseUrl}court/openmatch/pay-share-payment/$paymentId/accept-wallet";
      final response = await dioClient.post(
        endpoint,
        data: {},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "✅ Payment accepted successfully",
          level: LogLevel.info,
        );
        return response.data;
      } else {
        throw Exception("❌ Payment failed: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "❌ acceptWalletPayment failed: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }
}