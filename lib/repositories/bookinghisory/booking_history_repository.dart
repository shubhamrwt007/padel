import 'package:flutter/foundation.dart';
import 'package:padel_mobile/data/request_models/booking/update_new_court_booking_model.dart';
import 'package:padel_mobile/data/request_models/booking/update_refund_amount_model.dart';
import '../../core/endpoitns.dart';
import '../../core/network/dio_client.dart';
import '../../data/request_models/booking/boking_history_model.dart';
import '../../data/request_models/booking/booking_confermation_model.dart';
import '../../data/request_models/booking/cancel_booking_model.dart';
import '../../handler/logger.dart';
class BookingHistoryRepository {
  static final BookingHistoryRepository _instance = BookingHistoryRepository._internal();
  final DioClient dioClient = DioClient();
  factory BookingHistoryRepository() {
    return _instance;
  }

  BookingHistoryRepository._internal();

  Future<BookingHistoryModel> getBookingHistory({
    required String type,
    int page = 1,
    int limit = 10,
    String? categoryId,
    String? locationId,
  }) async {
    try {
      if (kDebugMode) {
        print("Making API call for type: $type, page: $page, limit: $limit, categoryId: $categoryId, locationId: $locationId");
      }
      if (kDebugMode) {
        print("Endpoint: ${AppEndpoints.bookingHistory}");
      }

      final queryParams = {
        'type': type,
        'page': page,
        'limit': limit,
      };
      
      if (categoryId != null && categoryId.isNotEmpty) {
        queryParams['categoryId'] = categoryId;
      }
      
      if (locationId != null && locationId.isNotEmpty) {
        queryParams['locationId'] = locationId;
      }

      final response = await dioClient.get(
        AppEndpoints.bookingHistory,
        queryParameters: queryParams,
      );

      if (kDebugMode) {
        print("Response status: ${response.statusCode}");
      }
      if (kDebugMode) {
        print("Response data: ${response.data}");
      }

      if (response.statusCode == 200) {
        CustomLogger.logMessage(
          msg: "Booking history fetched: ${response.data}",
          level: LogLevel.info,
        );

        final model = BookingHistoryModel.fromJson(response.data);
        if (kDebugMode) {
          print("Parsed model bookings count: ${model.data?.length ?? 0}");
        }
        return model;
      } else {
        throw Exception("Failed to fetch booking history. Status: ${response.statusCode}");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Repository error: $e");
      }
      CustomLogger.logMessage(
        msg: "Error fetching booking history: $e",
        level: LogLevel.error,
      );
      rethrow;
    }
  }
  Future<BookingConfirmationModel> getBookingConfirmation({
    required String id, // now only bookingId
  }) async {
    try {
      if (kDebugMode) {
        print("Making API call for booking confirmation for bookingId: $id");
      }

      final queryParams = {
        '_id': id,
      };

      final response = await dioClient.get(
        AppEndpoints.bookingConfirmation,
        queryParameters: queryParams,
      );

      if (kDebugMode) {
        print("Response status: ${response.statusCode}");
        print("Response data: ${response.data}");
      }

      if (response.statusCode == 200) {
        return BookingConfirmationModel.fromJson(response.data);
      } else {
        throw Exception(
          "Failed to fetch booking confirmation. Status: ${response.statusCode}",
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("Repository error: $e");
      }
      rethrow;
    }
  }

  Future<CancelUserBooking?> updateBookingStatus({
    required Map<String, dynamic> body,
  }) async {
    try {
      CustomLogger.logMessage(
        msg: "Update Booking Status request body: $body",
        level: LogLevel.info,
      );

      final response = await dioClient.put(
        AppEndpoints.cancelBooking,
        data: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Update Booking Status Success: ${response.data}",
          level: LogLevel.info,
        );
        return CancelUserBooking.fromJson(response.data);
      } else {
        throw Exception("Update Booking Status Failed with status code: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Update Booking Status failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      return null;
    }
  }

  ///Update New Court Booking Model---------------------------------------------
  Future<UpdateNewCourtBookingModel?> updateNewCourtBookingModel({
    required Map<String, dynamic> body,
  }) async {
    try {
      CustomLogger.logMessage(
        msg: "Update New Court Booking Model request body: $body",
        level: LogLevel.info,
      );

      final response = await dioClient.put(
        AppEndpoints.updateMultipleCourtIds,
        data: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Update New Court Booking Model Success: ${response.data}",
          level: LogLevel.info,
        );
        return UpdateNewCourtBookingModel.fromJson(response.data);
      } else {
        throw Exception("Update New Court Booking Model Failed with status code: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Update New Court Booking Model failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      return null;
    }
  }


  ///Update Refund Open Match Model---------------------------------------------
  Future<UpdateRefundAmountModel?> updateRefundAmount({
    required Map<String, dynamic> body,
  }) async {
    try {
      CustomLogger.logMessage(
        msg: "Update Refund Open Match Model request body: $body",
        level: LogLevel.info,
      );

      final response = await dioClient.put(
        AppEndpoints.refundOpenMatch,
        data: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Update Refund Open Match Model Success: ${response.data}",
          level: LogLevel.info,
        );
        return UpdateRefundAmountModel.fromJson(response.data);
      } else {
        throw Exception("Update Refund Open Match Model Failed with status code: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Update Refund Open Match Model failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      return null;
    }
  }

}
