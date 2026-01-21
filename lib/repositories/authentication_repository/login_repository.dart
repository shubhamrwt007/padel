import 'package:padel_mobile/data/request_models/logout_model.dart';

import '../../core/endpoitns.dart';
import '../../core/network/dio_client.dart';
import '../../data/request_models/authentication_models/login_model.dart';
import '../../data/request_models/authentication_models/otp_model.dart';
import '../../handler/logger.dart';

class LoginRepository {
  static final LoginRepository _instance = LoginRepository._internal();
  final DioClient dioClient = DioClient();

  factory LoginRepository() {
    return _instance;
  }

  LoginRepository._internal();

  Future<OTPModel> sendOTP({required Map<String, dynamic> body}) async {
    try {
      CustomLogger.logMessage(msg: "LOGIN OTP BODY:-> $body", level: LogLevel.info);
      final response = await dioClient.post(AppEndpoints.sendOTP, data: body);

      if (response.statusCode == 200) {
        CustomLogger.logMessage(
          msg: "Login OTP send successfully: ${response.data}",
          level: LogLevel.info,
        );
        return OTPModel.fromJson(response.data);
      } else {
        throw Exception(
          "Login OTP send failed with status code: ${response.statusCode}",
        );
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Login OTP send failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }


  Future<LoginModel> loginUser({required Map<String,dynamic> body}) async {


    try {
      CustomLogger.logMessage(
        msg: "LOGIN BODY:-> $body",
        level: LogLevel.info,
      );
      final response = await dioClient.post(AppEndpoints.login, data: body);

      if (response.statusCode == 200) {
        CustomLogger.logMessage(
          msg: "Login successful: ${response.data}",
          level: LogLevel.info,
        );
        return LoginModel.fromJson(response.data);
      } else {
        throw Exception("Login failed with status code: ${response.statusCode}");
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
  ///LogOut---------------------------------------------------------------------
  Future<LogOutModel> logOutUser({required Map<String,dynamic> body}) async {
    try {
      CustomLogger.logMessage(
        msg: "LOGOUT BODY:-> $body",
        level: LogLevel.info,
      );
      final response = await dioClient.put(AppEndpoints.logout, data: body);

      if (response.statusCode == 200) {
        CustomLogger.logMessage(
          msg: "LogOut successful: ${response.data}",
          level: LogLevel.info,
        );
        return LogOutModel.fromJson(response.data);
      } else {
        throw Exception("LogOut failed with status code: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "LogOut failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }
}