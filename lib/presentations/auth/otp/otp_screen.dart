import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/configs/app_colors.dart';

import 'package:padel_mobile/configs/app_strings.dart';
import 'package:padel_mobile/configs/components/app_bar.dart';
import 'package:padel_mobile/configs/components/primary_button.dart';
import 'package:padel_mobile/configs/components/primary_container.dart';
import 'package:padel_mobile/presentations/auth/otp/otp_controller.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../configs/components/loader_widgets.dart';

class OtpScreen extends GetView<OtpController> {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus!.unfocus(),
      child: PrimaryContainer(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: primaryAppBar(title: SizedBox(), context: context),
          body: enterOtp(context, controller),
        ),
      ),
    );
  }

  Widget enterOtp(BuildContext context, OtpController controller) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Center(
            child: Text(
              AppStrings.enterOtp,
              style: Theme.of(context).textTheme.titleLarge,
            ).paddingOnly(bottom: Get.height * 0.03, top: Get.height * 0.15),
          ),
          Text(
            'A security code has been sent to ${controller.getMaskedPhoneNumber()}. Please enter it below',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium!.copyWith(fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ).paddingOnly(bottom: Get.height * 0.057),
          PinCodeTextField(
            scrollPadding: EdgeInsets.only(bottom: Get.height*0.3),
            controller: controller.valueController,
            focusNode: controller.pinFocusNode,
            appContext: context,
            length: 4,
            cursorColor: AppColors.primaryColor,
            textStyle: Theme.of(context).textTheme.headlineLarge!.copyWith(
              fontWeight: FontWeight.w400,
              fontSize: 30,
              color: Colors.black,
            ),
            animationType: AnimationType.fade,
            keyboardType: TextInputType.number,
            animationCurve: Curves.easeInCubic,
            enableActiveFill: true,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(12),
              fieldHeight: 60,
              fieldWidth: 60,

              // Hide borders
              inactiveColor: Colors.transparent,
              selectedColor: AppColors.primaryColor,
              activeColor: Colors.transparent,
              borderWidth: 2,

              // Fill colors for background of boxes
              inactiveFillColor: Colors.grey.shade100,
              selectedFillColor: const Color(0xFFF1F4FF),
              activeFillColor: const Color(0xFFF1F4FF),
            ),
            backgroundColor: Colors.transparent,
            blinkWhenObscuring: true,
            autoDisposeControllers: true,
            beforeTextPaste: (text) => true,
            onChanged: (value) {
              controller.onOtpChanged(value);
            },
          ).paddingOnly(
            left: Get.width * 0.06,
            right: Get.width * 0.06,
            bottom: Get.height * 0.02,
          ),
          // Countdown timer
          Obx(() {
            final minutes = (controller.secondsRemaining.value ~/ 60).toString().padLeft(2, '0');
            final seconds = (controller.secondsRemaining.value % 60).toString().padLeft(2, '0');
            return Text(
              "$minutes:$seconds",
              style: Theme.of(context).textTheme.headlineMedium!.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ).paddingOnly(
              bottom: MediaQuery.of(context).viewInsets.bottom > 0
                  ? Get.height * 0.01
                  : Get.height * 0.25,
            );
          }),

          Obx(() {
            final isTimerFinished = controller.secondsRemaining.value == 0;
            final isResending = controller.isResending.value;

            return RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: AppStrings.doNotReceiveCode,
                    style: Get.textTheme.headlineLarge!.copyWith(
                      color: AppColors.darkGreyColor,
                    ),
                  ),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: (isTimerFinished && !isResending)
                          ? controller.resendOtp
                          : null,
                      child: Container(
                        color: Colors.transparent,
                        child: Text(
                          isResending
                              ? "Resend..."
                              : AppStrings.resend,
                          style: Get.textTheme.headlineMedium!.copyWith(
                            color: (isTimerFinished && !isResending)
                                ? AppColors.primaryColor
                                : Colors.grey,
                            decoration:isResending?TextDecoration.none: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          Obx(
            () => PrimaryButton(
              onTap: controller.isLoading.value
                  ? null
                  : () {
                      controller.verifyOTP();
                    },
              text: AppStrings.verify,
              child: controller.isLoading.value
                  ? AppLoader(size: 35, strokeWidth: 4)
                  : null,
            ).paddingOnly(bottom: Get.height * 0.04, top: Get.height * 0.03),
          ),
        ],
      ).paddingOnly(left: Get.width * 0.05, right: Get.width * 0.05),
    );
  }
}
