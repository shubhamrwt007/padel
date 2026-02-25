import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/configs/components/app_toast.dart';
import 'package:padel_mobile/presentations/booking/successful_screens/booking_successful_screen.dart';

class NumberVerifyBottomSheetController extends GetxController {
  RxInt selectedPlayer = 1.obs;
  RxBool otpSent = false.obs;
  RxBool isLoading = false.obs;

  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  void switchPlayer(int value) {
    selectedPlayer.value = value;
  }

  void getOtp() {
    otpSent.value = true;
    // Get.snackbar("OTP Sent", "OTP sent successfully");
  }

  void resendOtp() {
    // Get.snackbar("Resent", "OTP resent successfully");
  }

  void verifyAndPay() {
    if (otpController.text.length != 4) {
      AppToast.error("Enter valid 4 digit OTP");
      return;
    }
    Get.to(()=>BookingSuccessfulScreen(buttonType: "tournament",));
  }

  @override
  void onClose() {
    phoneController.dispose();
    super.onClose();
  }
}