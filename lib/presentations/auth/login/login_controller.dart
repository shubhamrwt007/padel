import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:padel_mobile/core/network/dio_client.dart';
import 'package:padel_mobile/data/request_models/authentication_models/login_model.dart';
import 'package:padel_mobile/handler/logger.dart';
import 'package:padel_mobile/handler/text_formatter.dart';
import 'package:padel_mobile/presentations/auth/login/widgets/login_exports.dart';
import 'package:padel_mobile/presentations/auth/otp/otp_controller.dart';
import 'package:padel_mobile/repositories/authentication_repository/login_repository.dart';
import 'package:padel_mobile/repositories/openmatches/open_match_repository.dart';
import 'package:padel_mobile/presentations/home/home_controller.dart';
import 'package:padel_mobile/presentations/main_home_page/main_home_controller.dart';
import 'package:padel_mobile/presentations/profile/profile_controller.dart';

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
        Fluttertoast.showToast(
          msg: "Phone number ${phoneController.text.trim()} not found. Please sign up first.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
          timeInSecForIosWeb: 3,
        );
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
        // Clear old data first
        await storage.remove('token');
        await storage.remove('userId');
        
        // Write new user data
        await storage.write('token', result.response!.token);
        await storage.write('userId', result.response!.user!.id);
        
        log("🔑 User logged in - userId: ${result.response!.user!.id}");
        
        // Delete old controllers to prevent showing old user data
        Get.delete<HomeController>(force: true);
        Get.delete<MainHomeController>(force: true);
        Get.delete<ProfileController>(force: true);
        
        Get.offAllNamed(RoutesName.bottomNav);
      }
    }on DioException catch (e) {
      final code = e.response?.statusCode;
      final message = e.response?.data?['message'] ?? 'Login failed';

      if (code == 404) {
        Fluttertoast.showToast(
          msg: message,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
          timeInSecForIosWeb: 3,
        );
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

      if (result.status == 200) {
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
