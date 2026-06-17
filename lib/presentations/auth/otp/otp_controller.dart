
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:otp_autofill/otp_autofill.dart';
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
  late OTPTextEditController otpController;
  late OTPInteractor otpInteractor;
  bool _otpToastShown = false;

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
        await getPurpose();
      } else if (result.status == "400") {
        AppToast.error(result.message!);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getPurpose() async {
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
    otpInteractor = OTPInteractor();
    otpController = OTPTextEditController(
      codeLength: 4,
      onCodeReceive: (code) {
        valueController.text = code;
        onOtpChanged(code);
      },
    )..startListenUserConsent((code) {
      final exp = RegExp(r'(\d{4})');
      return exp.stringMatch(code ?? '') ?? '';
    });
    startTimer();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   // Show OTP at top of screen only once
    //   if (arguments['otp'] != null && !_otpToastShown) {
    //     _otpToastShown = true;
    //     Future.delayed(const Duration(milliseconds: 500), () {
    //       Get.rawSnackbar(
    //         message: "OTP: ${arguments['otp']}",
    //         backgroundColor: Colors.green,
    //         snackPosition: SnackPosition.TOP,
    //         duration: const Duration(seconds: 5),
    //         margin: EdgeInsets.zero,
    //         borderRadius: 0,
    //         padding: EdgeInsets.only(
    //           top: Get.mediaQuery.padding.top + 10,
    //           bottom: 15,
    //           left: 20,
    //           right: 20,
    //         ),
    //       );
    //     });
    //   }
    // });
  }

  @override
  void onClose() {
    _timer?.cancel();
    otpController.stopListen();
    super.onClose();
  }
}
