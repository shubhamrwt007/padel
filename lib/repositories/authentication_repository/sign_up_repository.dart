import 'package:dio/dio.dart';
import 'package:padel_mobile/data/request_models/authentication_models/otp_model.dart';
import 'package:padel_mobile/data/request_models/authentication_models/reset_password.model.dart';
import 'package:padel_mobile/data/request_models/authentication_models/sign_up_model.dart';
import 'package:padel_mobile/data/request_models/common_model.dart';
import 'package:padel_mobile/data/response_models/get_locations_model.dart';

import '../../core/endpoitns.dart';
import '../../core/network/dio_client.dart';
import '../../handler/logger.dart';

class SignUpRepository {
  static final SignUpRepository _instance = SignUpRepository._internal();
  final DioClient dioClient = DioClient();

  factory SignUpRepository() {
    return _instance;
  }

  SignUpRepository._internal();

  Future<SignUpModel> createAccount({
    required Map<String, dynamic> body,
  }) async {
    try {
      CustomLogger.logMessage(
        msg: "Sign up BODY:-> $body",
        level: LogLevel.info,
      );
      final response = await dioClient.post(AppEndpoints.signUp, data: body);

      if (response.statusCode == 200) {
        CustomLogger.logMessage(
          msg: "Account created: ${response.data}",
          level: LogLevel.info,
        );
        return SignUpModel.fromJson(response.data);
      } else {
        throw Exception(
          "Sign up failed with status code: ${response.statusCode}",
        );
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Login failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }

  Future<OTPModel> sendOTP({required Map<String, dynamic> body}) async {
    try {
      CustomLogger.logMessage(msg: "OTP BODY:-> $body", level: LogLevel.info);
      final response = await dioClient.post(AppEndpoints.sendOTP, data: body);

      if (response.statusCode == 200) {
        CustomLogger.logMessage(
          msg: "OTP send successfully: ${response.data}",
          level: LogLevel.info,
        );
        return OTPModel.fromJson(response.data);
      } else {
        throw Exception(
          "OTP send failed with status code: ${response.statusCode}",
        );
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "OTP send failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }

  Future<CommonModel> verifyOTP({required Map<String, dynamic> body}) async {
    try {
      CustomLogger.logMessage(msg: "OTP BODY:-> $body", level: LogLevel.info);
      final response = await dioClient.post(AppEndpoints.verifyOTP, data: body);

      if (response.statusCode == 200) {
        CustomLogger.logMessage(
          msg: "OTP Verified successfully: ${response.data}",
          level: LogLevel.info,
        );
        return CommonModel.fromJson(response.data);
      } else {
        throw Exception(
          "OTP verification failed with status code: ${response.statusCode}",
        );
      }
    } on DioException catch (e, st) {
      CustomLogger.logMessage(
        msg: "OTP verification failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );

      // Handle 400 error response and return as CommonModel
      if (e.response != null && e.response!.statusCode == 400) {
        // Extract error message from response if available
        String errorMessage = "Invalid OTP";
        if (e.response!.data is Map) {
          errorMessage = e.response!.data['message'] ?? errorMessage;
        }

        return CommonModel(
          status: "400",
          message: errorMessage,
        );
      }

      // For other errors, rethrow
      rethrow;
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "OTP verification failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }
  Future<ResetPasswordModel> resetPassword({required Map<String, dynamic> body}) async {
    try {
      CustomLogger.logMessage(msg: "Reset Password body:-> $body", level: LogLevel.info);
      final response = await dioClient.put(AppEndpoints.resetPassword, data: body);

      if (response.statusCode == 200) {
        CustomLogger.logMessage(
          msg: "Reset Password successfully: ${response.data}",
          level: LogLevel.info,
        );
        return ResetPasswordModel.fromJson(response.data);
      } else {
        throw Exception(
          "Reset Password failed with status code: ${response.statusCode}",
        );
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Reset Password failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }
   ///Get Locations Api------------------------------------------------------------
  Future<GetLocationsModel> getLocations() async {
    try {
      final response = await dioClient.get(
        AppEndpoints.getLocations,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Get-Locations Data: ${response.data}",
          level: LogLevel.info,
        );
        return GetLocationsModel.fromJson(response.data);
      } else {
        throw Exception("Get-Locations failed: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Get-Locations failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }
}
