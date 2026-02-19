
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/configs/components/app_toast.dart';
import 'package:padel_mobile/presentations/auth/forgot_password/forgot_password_controller.dart';
import 'package:padel_mobile/presentations/auth/forgot_password/widgets/reset_password_screen.dart';
import 'package:padel_mobile/presentations/auth/login/login_controller.dart';
import 'package:padel_mobile/repositories/authentication_repository/sign_up_repository.dart';

import '../../../configs/components/snack_bars.dart';
import '../sign_up/sign_up_controller.dart';

enum OtpScreenType { createAccount, forgotPassword, login }

class OtpController extends GetxController {
  SignUpRepository signUpRepository = SignUpRepository();
  SignUpController signUpController = Get.put(SignUpController());
  ForgotPasswordController forgotPasswordController = Get.put(ForgotPasswordController());
  LoginController loginController = Get.put(LoginController());

  final TextEditingController valueController = TextEditingController();
  final FocusNode pinFocusNode = FocusNode();
  final arguments = Get.arguments;
  RxBool isLoading = false.obs;

  String getMaskedPhoneNumber() {
    final phoneNumber = arguments['phoneNumber'] ?? '';
    if (phoneNumber.length >= 4) {
      final lastFour = phoneNumber.substring(phoneNumber.length - 4);
      return '+91******$lastFour';
    }
    return phoneNumber;
  }

  void onOtpChanged(String value) {
    if (value.length == 4) {
      verifyOTP();
    }
  }

  Future<void> verifyOTP() async {
    FocusManager.instance.primaryFocus!.unfocus();
    try {
      if (isLoading.value) return;
      isLoading.value = true;
      Map<String, dynamic> body = {
        // "email": arguments['email'],
        "phoneNumber": arguments['phoneNumber'],
        "otp": valueController.text.trim(),
      };
      var result = await signUpRepository.verifyOTP(body: body);
      if (result.status == "200") {
        getPurpose();
      } else if (result.status == "400") {
        AppToast.error(result.message!);
      }
    } finally {
      isLoading.value = false;
    }
  }

  void getPurpose() async {
    if (OtpScreenType.createAccount == arguments['type']) {
      await signUpController.createAccount();
    } else if (OtpScreenType.login == arguments['type']) {
      await loginController.onLogin();
    } else {
     Get.to(()=>ResetPasswordScreen());
    }
  }

  var isResending = false.obs;

  Future<void> resendOtp() async {
    if (isResending.value) return;
    isResending.value = true;
    valueController.clear();
    if (arguments['type'] == OtpScreenType.createAccount) {
      await signUpController.sendOTP();
    } else if (arguments['type'] == OtpScreenType.login) {
      await loginController.sendOTP();
    } else {
      await forgotPasswordController.sendOTP();
    }

    isResending.value = false;
    startTimer();
    pinFocusNode.requestFocus();

  }
  Timer? _timer;
  RxInt secondsRemaining = 60.obs;
  void startTimer() {
    _timer?.cancel();
    secondsRemaining.value = 60;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining.value > 0) {
        secondsRemaining.value--;
      } else {
        _timer?.cancel();
      }
    });
  }
  @override
  void onInit() {
    super.onInit();
    startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      pinFocusNode.requestFocus();
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    // pinFocusNode.dispose();
    super.onClose();
  }
}
