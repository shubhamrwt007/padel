import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/components/app_bar.dart';
import 'package:padel_mobile/configs/components/custom_button.dart';
import 'package:padel_mobile/configs/components/snack_bars.dart';
import 'package:padel_mobile/generated/assets.dart';
import 'package:padel_mobile/handler/text_formatter.dart';
import 'package:padel_mobile/presentations/payment/payment_method_controller.dart';
import 'package:padel_mobile/presentations/cart/cart_controller.dart';
import 'package:padel_mobile/presentations/book_a_court/book_a_court_controller.dart';

class PaymentMethodScreen extends GetView<PaymentMethodController> {
  const PaymentMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CartController cartController = Get.find<CartController>();

    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: primaryAppBar(
        centerTitle: true,
        title: Text("Payment"),
        // action: [
        //   Container(
        //     alignment: Alignment.center,
        //     height: 24,
        //     width: 24,
        //     decoration: BoxDecoration(
        //       borderRadius: BorderRadius.circular(4),
        //       border: Border.all(color: AppColors.blackColor, width: 2),
        //     ),
        //     child: Icon(Icons.add, size: 20),
        //   ).paddingOnly(right: 10),
        // ],
        context: context,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment Summary Section
            _buildPaymentSummary(context, cartController),

            // UPI Section
            Text(
              "UPI",
              style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ).paddingSymmetric(horizontal: Get.width * 0.05),

            _buildUPIOptions(context),

            SizedBox(height: Get.height * 0.03),

            // Credit & Debit Cards Section
            Text(
              "Credit & Debit Cards",
              style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ).paddingSymmetric(horizontal: Get.width * 0.05),

            SizedBox(height: Get.height * 0.02),

            _buildCardOptions(context),

            SizedBox(height: Get.height * 0.03),
          ],
        ),
      ),
      // bottomNavigationBar: _buildPaymentButton(context, cartController),
    );
  }

  Widget _buildPaymentSummary(BuildContext context, CartController cartController) {
    final BookACourtController? bookACourtController = Get.isRegistered<BookACourtController>() 
        ? Get.find<BookACourtController>() 
        : null;
    final bool isFromBookACourt = bookACourtController != null && bookACourtController.realCourtSelections.isNotEmpty;
    
    return Obx(() {
      final walletBalance = controller.walletAmountUsed.value;
      final amountToPay = controller.razorpayAmountUsed.value;
      final totalAmount = walletBalance + amountToPay;

      return Container(
        margin: EdgeInsets.all(Get.width * 0.05),
        padding: EdgeInsets.all(Get.width * 0.05),
        decoration: BoxDecoration(
          color: Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Payment Summary",
              style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: Get.height * 0.02),
            _buildSummaryRow(context, "Total Amount", "₹${formatAmount(totalAmount.toString())}", false),
            SizedBox(height: Get.height * 0.015),
            _buildSummaryRow(context, "Less: Wallet Balance", "- ₹${formatAmount(walletBalance.toString())}", true),
            SizedBox(height: Get.height * 0.015),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Amount To Pay",
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "₹${formatAmount(amountToPay.toString())}",
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value, bool isDeduction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(
            color: isDeduction ? Colors.red : AppColors.blackColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildUPIOptions(BuildContext context) {
    final upiOptions = [
      {
        "name": "Google Pay",
        "icon": Assets.imagesImgGooglePay,
        "value": "google_pay",
        "hasButton": true,
      },
      {
        "name": "Paytm",
        "icon": Assets.imagesImgPaytm, // Add this asset
        "value": "paytm",
        "hasButton": true,
      },
      {
        "name": "PhonePe",
        "icon": Assets.imagesImgPhonePay, // Add this asset
        "value": "phonepe",
        "hasButton": true,
      },
      {
        "name": "Other Ways",
        "icon": Assets.imagesImgOtherUpi, // Add this asset
        "value": "other_ways",
        "hasButton": true,
      },
    ];

    return Column(
      children: upiOptions.map((option) {
        return _buildPaymentOption(
          context,
          option['icon']! as String,
          option['name']! as String,
          option['value']! as String,
          hasButton: option['hasButton']! as bool,
        );
      }).toList(),
    );
  }

  Widget _buildCardOptions(BuildContext context) {
    return Column(
      children: [
        _buildPaymentOption(
          context,
          "", // Add this asset
          "Visa",
          "visa_1324",
          subtitle: "**1324 | Vikram Kumar",
        ),
        SizedBox(height: Get.height * 0.015),
        GestureDetector(
          onTap: () {
            // Navigate to add card screen
          },
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: Get.width * 0.05),
            child: Row(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  "Add a new credit or debit card",
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(
      BuildContext context,
      String iconPath,
      String title,
      String value, {
        String? subtitle,
        bool hasButton = false,
      }) {
    return GestureDetector(
      onTap: () {
        if (value.startsWith('visa') || value.contains('card')) {
          // SnackBarUtils.showInfoSnackBar("Coming Soon");
        } else {
          controller.option.value = value;
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: Get.width * 0.05,
          vertical: Get.height * 0.008,
        ),
        padding: EdgeInsets.all(Get.width * 0.04),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: Obx(() {
          return Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: iconPath.isEmpty
                        ? Center(
                            child: Text(
                              title[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          )
                        : Image.asset(
                            iconPath,
                            fit: BoxFit.contain,
                          ),
                  ),
                  SizedBox(width: Get.width * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Radio<String>(
                    value: value,
                    groupValue: controller.option.value,
                    onChanged: (val) {
                      controller.option.value = val!;
                    },
                    activeColor: AppColors.primaryColor,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
              AnimatedSize(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: hasButton && controller.option.value == value
                    ? Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (controller.razorpayAmountUsed.value <= 0) {
                                SnackBarUtils.showWarningSnackBar("Amount cannot be zero");
                                return;
                              }
                              await controller.startPayment();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              "Pay using ${title}",
                              style: TextStyle(
                                color: AppColors.whiteColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      )
                    : SizedBox.shrink(),
              ),
            ],
          );
        }),
    ));
  }

  Widget _buildPaymentButton(BuildContext context, CartController cartController) {
    final BookACourtController? bookACourtController = Get.isRegistered<BookACourtController>() 
        ? Get.find<BookACourtController>() 
        : null;
    final bool isFromBookACourt = bookACourtController != null && bookACourtController.realCourtSelections.isNotEmpty;
    
    return Container(
      padding: EdgeInsets.all(Get.width * 0.05),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Obx(() {
        final int totalAmount = isFromBookACourt
            ? bookACourtController.totalAmount.value
            : cartController.totalPrice.value;
        
        return CustomButton(
          width: Get.width,
          onTap: () async {
            if (controller.option.value.isEmpty) {
              SnackBarUtils.showWarningSnackBar("Please select payment method");
              return;
            }

          if (!isFromBookACourt) {
            if (cartController.cartItems.isEmpty) {
              // SnackBarUtils.showWarningSnackBar("Cart is empty");
              return;
            }
          }

            // Use Razorpay payment for both platforms
            await controller.startPayment();
          },
          child: controller.isProcessing.value || cartController.isBooking.value
              ? LoadingAnimationWidget.waveDots(
            color: AppColors.whiteColor,
            size: 45,
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "₹",
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: AppColors.whiteColor,
                  fontFamily: "Roboto",
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 5),
              Text(
                formatAmount(totalAmount.toString()),
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: AppColors.whiteColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 20),
              Text(
                "Book Now",
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  color: AppColors.whiteColor,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}