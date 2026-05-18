import 'package:padel_mobile/core/endpoitns.dart';
import 'package:padel_mobile/data/request_models/FireBase%20Token%20Update/update_fcm_token_model.dart';
import 'package:padel_mobile/handler/logger.dart';

import '../../core/network/dio_client.dart';

class FcmTokenRepository {
  static final FcmTokenRepository _instance = FcmTokenRepository._internal();
  final DioClient dioClient = DioClient();

  factory FcmTokenRepository() {
    return _instance;
  }

  FcmTokenRepository._internal();

  Future<UpdateFcmTokenModel> updateFcmToken({required Map<String, dynamic> body}) async {
    try {
      CustomLogger.logMessage(msg: "FCM TOKEN BODY:-> $body", level: LogLevel.info);
      final response = await dioClient.put(AppEndpoints.updateFcmToken, data: body);

      if (response.statusCode == 200) {
        CustomLogger.logMessage(
          msg: "FCM TOKEN update successfully: ${response.data}",
          level: LogLevel.info,
        );
        return UpdateFcmTokenModel.fromJson(response.data);
      } else {
        throw Exception(
          "FCM TOKEN failed with status code: ${response.statusCode}",
        );
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "FCM TOKEN failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }
}