import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/components/custom_button.dart';
import 'package:padel_mobile/configs/components/fade_divider.dart';
import 'package:padel_mobile/configs/components/primary_text_feild.dart';
import 'package:padel_mobile/presentations/tournaments/number_verify_bottomsheet/number_verify_bottom_sheet_controller.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class NumberVerifyBottomSheet extends StatelessWidget {
  NumberVerifyBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NumberVerifyBottomSheetController(), tag: DateTime.now().toString());

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Container(
        height: Get.height * .55,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// Header
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Icon(Icons.arrow_back,size: 24,),
                      ),
                      const Spacer(),
                      Text(
                        "Number Verify",
                        style: Get.textTheme.headlineMedium,
                      ),
                      const Spacer(),
                    ],
                  ).paddingOnly(bottom: 10),
                  fadeDivider().paddingOnly(bottom: 10),

                  /// Toggle
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _toggle("Player 1", 1,controller),
                        _toggle("Player 2", 2,controller),
                      ],
                    ),
                  ).paddingOnly(bottom: 20),
                  /// Phone
                  Text("Phone Number",
                      style: Get.textTheme.bodySmall!.copyWith(color: Colors.black)),

                  const SizedBox(height: 8),

                  PrimaryTextField(
                    maxLength: 10,
                      suffixIcon: Container(
                        margin: EdgeInsets.all(5),
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: AppColors.primaryColor.withValues(alpha: 0.2)
                        ),
                        child: Text("Get OTP",style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500,color: AppColors.primaryColor),).paddingOnly(top: 10),
                      ),
                      hintStyle:Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500),
                      style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500),
                      hintText: "Enter phone number"),

                  const SizedBox(height: 20),

                  Text("Enter OTP",
                      style: Get.textTheme.bodySmall!.copyWith(color: Colors.black)),

                  const SizedBox(height: 12),

                  /// OTP Boxes
                  PinCodeTextField(
                    appContext: context,
                    length: 4,
                    cursorColor: AppColors.primaryColor,
                    separatorBuilder: (context, index) => const SizedBox(width: 10),
                    textStyle: Get.textTheme.headlineLarge!.copyWith(
                      fontWeight: FontWeight.w400,
                      fontSize: 18,
                      color: Colors.black,
                    ),
                    cursorHeight: 30,
                    controller: controller.otpController,
                    keyboardType: TextInputType.number,
                    animationType: AnimationType.fade,
                    animationCurve: Curves.easeInCubic,
                    enableActiveFill: true,
                    mainAxisAlignment: MainAxisAlignment.start,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(12),
                      fieldHeight: 50,
                      fieldWidth: 50,

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
                    onChanged: (value) {},
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Text("Don’t receive code ? ",style: Get.textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w600),),
                      GestureDetector(
                        onTap: controller.resendOtp,
                        child: Text(
                          "Re-send",
                          style: Get.textTheme.labelSmall!.copyWith(color: AppColors.primaryColor,fontWeight: FontWeight.w600),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _bottomButton(context,controller))
          ],
        ),
      ),
    );
  }

  Widget _toggle(
      String title, int value,NumberVerifyBottomSheetController controller) {
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.switchPlayer(value),
        child: Obx(() => Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: controller.selectedPlayer.value == value
                ? AppColors.primaryColor
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style:Get.textTheme.bodySmall!.copyWith( color: controller.selectedPlayer.value == value
                ? Colors.white
                : Colors.black,)
          ),
        )),
      ),
    );
  }
  Widget _bottomButton(BuildContext context,NumberVerifyBottomSheetController controller){
    return Container(
      height: Get.height * .09,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: CustomButton(
        width: Get.width * 0.9,
        child: Text(
          "Payment",
          style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: AppColors.whiteColor),
        ).paddingOnly(right: Get.width * 0.14),
        onTap: () {
          controller.verifyAndPay();
        },
      ).paddingOnly(bottom: 0),
    );
  }
}