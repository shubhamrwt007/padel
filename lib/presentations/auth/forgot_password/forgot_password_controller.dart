import 'package:padel_mobile/configs/components/app_toast.dart';
import 'package:padel_mobile/handler/logger.dart';
import 'package:padel_mobile/handler/text_formatter.dart';
import 'package:padel_mobile/presentations/auth/forgot_password/widgets/forgot_password_exports.dart';

import '../../../configs/components/snack_bars.dart';
import '../../../configs/routes/routes_name.dart';
import '../../../repositories/authentication_repository/sign_up_repository.dart';
import '../login/login_screen.dart';
import '../otp/otp_controller.dart';

class ForgotPasswordController extends GetxController {
  TextEditingController emailController = TextEditingController();
  TextEditingController pwdController = TextEditingController();
  TextEditingController cnfPwdController = TextEditingController();
  SignUpRepository signUpRepository = SignUpRepository();

  GlobalKey<FormState> resetFormKey = GlobalKey<FormState>();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  RxBool isLoading = false.obs;
  RxBool isOTPLoading = false.obs;
  RxBool isVisiblePassword = true.obs;
  RxBool isVisibleConfirmPassword = true.obs;

  void passwordToggle() {
    isVisiblePassword.value = !isVisiblePassword.value;
  }

  void confirmPasswordToggle() {
    isVisibleConfirmPassword.value = !isVisibleConfirmPassword.value;
  }

  String? validatePassword() {
    if (pwdController.text.isEmpty) {
      return AppStrings.passwordRequired;
    } else if (!pwdController.text.isValidPassword) {
      return AppStrings.invalidPassword;
    }
    return null;
  }

  String? validateConfirmPassword() {
    if (cnfPwdController.text.isEmpty) {
      return AppStrings.passwordRequired;
    } else if (cnfPwdController.text != pwdController.text) {
      return AppStrings.invalidConfirmPassword;
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.emailRequired;
    } else if (!value.isValidEmail) {
      return AppStrings.invalidEmail;
    }
    return null;
  }

  Future<void> sendOTP() async {
    try {
      if (isOTPLoading.value) return;
      isOTPLoading.value = true;
      Map<String, dynamic> body = {
        "email": emailController.text.trim(),
        "type": "Forgot",
        "countryCode": "+91",
        "phoneNumber": 0,
      };
      var result = await signUpRepository.sendOTP(body: body);
      if (result.status == "200") {
        Get.toNamed(
          RoutesName.otp,
          arguments: {
            "email": emailController.text.trim(),
            "type": OtpScreenType.forgotPassword,
          },
        );
        AppToast.success("OTP sent successfully");
      } else {
        AppToast.error(result.message??"");
      }
    } finally {
      isOTPLoading.value = false;
    }
  }

  Future<void> resetPassword() async {
    if (resetFormKey.currentState!.validate()) {
      try {
        if (isLoading.value) return;
        isLoading.value = true;
        Map<String, dynamic> body = {
          "email": emailController.text.trim(),
          "password": pwdController.text.trim(),
        };
        var response = await signUpRepository.resetPassword(body: body);
        if (response.status == "200") {
          Get.offAll(()=>LoginScreen());
          AppToast.success("Password Updated Successfully");
        } else {
          AppToast.error(response.message??"");

        }
      } catch (e) {
        CustomLogger.logMessage(msg: e, level: LogLevel.error);
      } finally {
        isLoading.value = false;
      }
    }
  }

  @override
  void onClose() {
    super.onClose();
    emailController.dispose();
    pwdController.dispose();
    cnfPwdController.dispose();
  }
  @override
  void onInit() {
    super.onInit();
    emailController.clear();
    pwdController.clear();
    cnfPwdController.clear();
  }

}
