import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/components/custom_button.dart';
import 'package:padel_mobile/configs/components/loader_widgets.dart';
import 'package:padel_mobile/configs/components/primary_button.dart';
import 'package:padel_mobile/configs/components/snack_bars.dart';
import 'package:padel_mobile/presentations/booking/book_session/widgets/upword_arrow_animation.dart';
import '../../../../data/request_models/home_models/get_available_court.dart';
import '../../../../handler/text_formatter.dart';
import 'questions_bottomsheet_controller.dart';

class QuestionsBottomsheetScreen extends StatelessWidget {
  QuestionsBottomsheetScreen({super.key});

  final QuestionsBottomsheetController controller = Get.find<QuestionsBottomsheetController>(tag: 'questions');
  final RxBool isExpanded = false.obs;

  @override
  Widget build(BuildContext context) {
    // Initialize match after data is set
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.razorpayAmountUsed.value == 0) {
        controller.initializeMatch();
      }
    });
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
        // ---------- FORM ----------
        _buildDropdown('Select game level'),
        const SizedBox(height: 6),
        _buildDropdown('Select game type'),
        const SizedBox(height: 6),
        _buildDropdown('Select match type'),
          const SizedBox(height: 20),
        // ---------- PAYMENT PANEL ----------
        Stack(
          clipBehavior: Clip.none,
          children: [
            Obx(() => AnimatedSize(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF003AFF),Color(0xFF07289A),],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Expandable slot details section
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 300),
                      crossFadeState: isExpanded.value
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: const SizedBox.shrink(),
                      secondChild: Column(
                        children: [
                          _buildSlotDetails(),
                          // const SizedBox(height: 16),
                        ],
                      ),
                    ),

                  // Total row
                  GestureDetector(
                    onTap: () {
                      isExpanded.value = !isExpanded.value;
                    },
                    onVerticalDragEnd: (details) {
                      if (details.primaryVelocity! < 0) {
                        isExpanded.value = true;
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Text(
                              'Total to Pay',
                              style: Get.textTheme.bodyMedium!.copyWith(color: Colors.white)
                            ),
                            Text(
                              'Wallet: ₹${controller.walletAmountUsed.value}',
                              style: Get.textTheme.bodySmall!.copyWith(color: Colors.white.withValues(alpha: 0.8))
                            ),
                          ],
                        ),
                        Text(
                          '₹ ${controller.razorpayAmountUsed.value}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Wallet
                  // _paymentTile(
                  //   title: 'Wallet',
                  //   subtitle: 'Current Balance: ₹0',
                  //   trailingColor: Colors.blue,
                  //   onTap: () {
                  //     Get.snackbar('Info', 'Wallet payment coming soon!');
                  //   },
                  // ),
                    CustomButton(
                      width: Get.width*0.9,
                      height: 55,
                      circleColor: AppColors.primaryColor,
                      gradientColors: [Colors.white,Colors.white,Colors.white],
                        onTap: () {
                        if(Get.isSnackbarOpen)return;
                          if (!controller.validateSelections()) {
                            return;
                          }
                          SnackBarUtils.showInfoSnackBar("Wallet payment coming soon!");
                        },
                      child:Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Wallet",style:Get.textTheme.headlineLarge!.copyWith(color: AppColors.primaryColor,fontSize: 16)),
                          Text("Current Balance: ₹0",style:Get.textTheme.bodySmall!.copyWith(color: AppColors.primaryColor,fontSize: 11)),
                        ],
                      ).paddingOnly(right: 40),
                    ),
                  const SizedBox(height: 12),

                  // Direct Payment
                  // Obx(() => _paymentTile(
                  //   title: 'Direct Payment',
                  //   titleColor: const Color(0xFF6FCF97),
                  //   trailingColor: const Color(0xFF6FCF97),
                  //   onTap: controller.isProcessing.value ? null : () {
                  //     controller.initiatePaymentAndCreateMatch();
                  //   },
                  //   isLoading: controller.isProcessing.value,
                  // )),
                    // In QuestionsBottomsheetScreen widget, update the Direct Payment button:
                    CustomButton(
                      width: Get.width * 0.9,
                      height: 55,
                      gradientColors: [Colors.white, Colors.white, Colors.white],
                      onTap: controller.isProcessing.value ? null : () {
                        if (Get.isSnackbarOpen) return;
                        controller.onDirectPaymentTap();
                      },
                      child: controller.isProcessing.value == true
                          ? LoadingAnimationWidget.waveDots(
                        color: AppColors.blackColor,
                        size: 45,
                      ).paddingOnly(right: 40)
                          : Obx(() => Text(
                        controller.requiresPayment.value
                            ? (Platform.isIOS ? "Direct Payment" : "Create Match")
                            : "Confirm Match",
                        style: Get.textTheme.headlineLarge!.copyWith(
                          color: AppColors.secondaryColor,
                          fontSize: 16,
                        ),
                      )).paddingOnly(right: 40),
                    )
                  ],
                ),
              ),
            )),
            Positioned(
              top: -14,
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  isExpanded.value = !isExpanded.value;
                },
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity! < 0) {
                    isExpanded.value = true;
                  }
                },
                // customBorder: const CircleBorder(),
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: 0.6,
                    child: Container(
                      height: 55,
                      width: 55,
                      decoration: BoxDecoration(
                        color: Color(0xFF003AFF),
                        shape: BoxShape.circle,
                        // boxShadow: [
                        //   BoxShadow(
                        //     color: Colors.grey.withValues(alpha: 0.1),
                        //     blurRadius: 1,
                        //     spreadRadius: -2,
                        //     offset: Offset(0, -5),
                        //   ),
                        // ],
                      ),
                      child: Transform.translate(
                        offset: Offset(0, -5),
                        child: Obx(() => ArrowAnimation(isUpward: !isExpanded.value,color: Colors.white,)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        ],
        ),
      ),
    );
  }

  // ---------- DROPDOWN ----------
  Widget _buildDropdown(String label) {
    List<String> items = [];
    RxString selectedValue = ''.obs;

    if (label == 'Select game level') {
      items = ['Beginner', 'Intermediate', 'Advanced', 'Professional'];
      selectedValue = controller.selectedGameLevel;
    } else if (label == 'Select game type') {
      items = ['Male Only', 'Female Only', 'Mixed Doubles'];
      selectedValue = controller.selectedGameType;
    } else if (label == 'Select match type') {
      items = ['Friendly', 'Competitive'];
      selectedValue = controller.selectedMatchType;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:Get.textTheme.headlineSmall!.copyWith(color: AppColors.primaryColor),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: Obx(() => DropdownButton<String>(
              hint: Text('Select',style: Get.textTheme.bodyLarge!.copyWith(color: AppColors.textColor)),
              isExpanded: true,
              dropdownColor: Colors.white,
              value: selectedValue.value.isEmpty ? null : selectedValue.value,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item,style: Get.textTheme.bodyLarge!.copyWith(color: AppColors.textColor)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  selectedValue.value = newValue;
                }
              },
            )),
          ),
        ),
      ],
    );
  }

  // ---------- PAYMENT TILE ----------
  Widget _paymentTile({
    required String title,
    String? subtitle,
    Color titleColor = Colors.black,
    required Color trailingColor,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
            ),
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: trailingColor,
                shape: BoxShape.circle,
              ),
              child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- SLOT DETAILS ----------
  Widget _buildSlotDetails() {
    final matchDate = controller.localMatchData["matchDate"];
    
    String formattedDate = '';
    if (matchDate != null) {
      final date = matchDate is DateTime
          ? matchDate
          : DateTime.tryParse(matchDate.toString());
      if (date != null) {
        formattedDate = DateFormat('dd, MMM').format(date);
      }
    }

    // Get grouped consecutive slots from controller
    final consecutiveGroups = controller.getGroupedSlots();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Summary:',
          style: Get.textTheme.headlineSmall!.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        // Display grouped slots
        ...consecutiveGroups.map((group) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: Get.textTheme.bodyMedium!.copyWith(color: Colors.white),
                      children: [
                        TextSpan(
                          text: '$formattedDate ${group['timeRange']} ',
                          style: Get.textTheme.labelSmall!.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        TextSpan(
                          text: controller.localMatchData["courtName"]?.toString() ?? 'Court',
                          style: Get.textTheme.labelSmall!.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  '₹ ${group['totalAmount']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.delete_outline,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 8),
        Divider(color: Colors.white.withOpacity(0.25)),
        const SizedBox(height: 8),
      ],
    );
  }

}
