import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:padel_mobile/core/network/dio_client.dart';
import 'package:padel_mobile/data/request_models/authentication_models/login_model.dart';
import 'package:padel_mobile/handler/logger.dart';
import 'package:padel_mobile/handler/text_formatter.dart';
import 'package:padel_mobile/presentations/auth/login/widgets/login_exports.dart';
import 'package:padel_mobile/presentations/auth/otp/otp_controller.dart';
import 'package:padel_mobile/repositories/authentication_repository/login_repository.dart';
import 'package:padel_mobile/repositories/openmatches/open_match_repository.dart';

import '../../../configs/components/snack_bars.dart';
import '../../notification/notification_controller.dart';

class LoginController extends GetxController {
  //Login Repository
  final LoginRepository loginRepository = LoginRepository();
  OpenMatchRepository openMatchRepository = Get.put(OpenMatchRepository());

  // Text Controllers
  // TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  // Focus Nodes
  FocusNode emailFocusNode = FocusNode();
  FocusNode passwordFocusNode = FocusNode();

  // Observable variables
  RxBool isVisible = true.obs;
  RxBool isLoading = false.obs;
  var numberLoader = false.obs;

  // Toggle password visibility
  void eyeToggle() {
    isVisible.value = !isVisible.value;
  }

  void onFieldSubmitted() async {
    if (emailFocusNode.hasFocus) {
      emailFocusNode.unfocus();
      passwordFocusNode.requestFocus();
    } else {
      passwordFocusNode.unfocus();
      await onLogin();
    }
  }
  // String? validateEmail(String? value) {
  //   if (value == null || value.isEmpty) {
  //     return AppStrings.emailRequired;
  //   } else if (!value.isValidEmail) {
  //     return AppStrings.invalidEmail;
  //   }
  //   return null;
  // }
  // String? validatePassword(String? value) {
  //   if (value == null || value.isEmpty) {
  //     return AppStrings.passwordRequired;
  //   } else if (!value.isValidPassword) {
  //     return AppStrings.invalidPassword;
  //   }
  //   return null;
  // }
  Future<void> sendOTP() async {
    FocusManager.instance.primaryFocus!.unfocus();
    try {
      if (isLoading.value) return;
      isLoading.value = true;

      bool userExists = await getUserDataFromNumber(phoneController.text.trim());
      
      if (userExists) {
        final Map<String, dynamic> body = {
          "phoneNumber": phoneController.text.trim(),
          "type": "Signup",
        };

        var result = await loginRepository.sendOTP(body: body);
        if (result.status == "200") {
          Get.toNamed(RoutesName.otp, arguments: {
            'phoneNumber': phoneController.text.trim(),
            'type': OtpScreenType.login,
          });
        } else {
          CustomLogger.logMessage(msg: result.message!, level: LogLevel.error);
        }
      } else {
        SnackBarUtils.showErrorSnackBar("Phone number ${phoneController.text.trim()} not found. Please sign up first.");
      }
    } catch (e) {
      log(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> onLogin() async {
    FocusManager.instance.primaryFocus!.unfocus();
    try {
      if (isLoading.value) return;
      // Try to read FCM token from storage; if empty, proactively fetch via NotificationController
      String? firebaseToken = storage.read('firebase_token');
      if (firebaseToken == null || firebaseToken.isEmpty) {
        final notificationController = NotificationController.instance;
        // Ensure permissions and try to refresh token
        await notificationController.requestPermissions();
        await notificationController.refreshToken();
        firebaseToken = notificationController.getStoredToken();
      }
      isLoading.value = true;
      final Map<String, dynamic> body = {
        "phoneNumber": phoneController.text.trim(),
      };
      // Only include fcmToken if we have a non-empty value
      if (firebaseToken != null && firebaseToken.isNotEmpty) {
        body["fcmToken"] = firebaseToken;
      }

      LoginModel result = await loginRepository.loginUser(body: body);
      if (result.status == "200") {
        storage.write('token', result.response!.token);
        storage.write('userId', result.response!.user!.id);
        Get.offAllNamed(RoutesName.bottomNav);
      }
    }on DioException catch (e) {
      final code = e.response?.statusCode;
      final message = e.response?.data?['message'] ?? 'Login failed';

      if (code == 404) {
        SnackBarUtils.showErrorSnackBar(message);
        CustomLogger.logMessage(msg: message, level: LogLevel.error);
      }
    }  catch (e) {
      log(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> getUserDataFromNumber(String phoneNumber) async {
    if (phoneNumber.length != 10) return false;

    try {
      numberLoader.value = true;
      final result = await openMatchRepository.getCustomerNameByPhoneNumber(
          phoneNumber: phoneNumber);

      if (result.result != null && result.result?.name != null && result.result!.name!.isNotEmpty) {
        return true; // User found
      } else {
        return false; // User not found
      }

    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Failed to fetch user data: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      return false; // Error means user not found
    } finally {
      numberLoader.value = false;
    }
  }

  @override
  void onClose() {
    // emailController.dispose();
    // passwordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    super.onClose();
  }

}
