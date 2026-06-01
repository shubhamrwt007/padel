import 'package:dio/dio.dart';
import 'package:padel_mobile/core/endpoitns.dart';
import 'package:padel_mobile/core/network/dio_client.dart';
import 'package:padel_mobile/data/response_models/americano_models/get_americano_model.dart';
import 'package:padel_mobile/handler/logger.dart';

class AmericanoRepository {
  static final AmericanoRepository _instance = AmericanoRepository._internal();
  final DioClient dioClient = DioClient();

  factory AmericanoRepository() {
    return _instance;
  }

  AmericanoRepository._internal();

  /// Get Americano Matches with Pagination-------------------------------------
  Future<GetAmericanoModel?> getAmericanos({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'limit': limit,
      };

      CustomLogger.logMessage(
        msg: "Fetching Americano Matches: $queryParams",
        level: LogLevel.info,
      );

      final response = await dioClient.get(
        AppEndpoints.getAmericanos,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Americano Matches fetched successfully: ${response.data}",
          level: LogLevel.info,
        );
        return GetAmericanoModel.fromJson(response.data);
      } else {
        throw Exception(
          "Failed to fetch Americano matches. Status code: ${response.statusCode}",
        );
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Error fetching Americano matches: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }

  /// Register player for Americano Match---------------------------------------
  Future<Response> registerPlayer({
    required String americanoMatchId,
    String? razorpayPaymentId,
    String? razorpayOrderId,
    String? razorpaySignature,
  }) async {
    try {
      final Map<String, dynamic> data = {
        "americanoMatchId": americanoMatchId,
      };

      if (razorpayPaymentId != null) {
        data['razorpay_payment_id'] = razorpayPaymentId;
      }
      if (razorpayOrderId != null) {
        data['razorpay_order_id'] = razorpayOrderId;
      }
      if (razorpaySignature != null) {
        data['razorpay_signature'] = razorpaySignature;
      }

      CustomLogger.logMessage(
        msg: "Registering player for Americano Match: $data",
        level: LogLevel.info,
      );

      final Response response = await dioClient.post(
        AppEndpoints.registerPlayer,
        data: data,
      );

      return response;
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Error registering player for Americano Match: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }
}
