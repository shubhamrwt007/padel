import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/components/app_bar.dart';
import 'package:padel_mobile/generated/assets.dart';
import 'package:padel_mobile/handler/text_formatter.dart';
import 'package:padel_mobile/presentations/wallet/wallet_controller.dart';
class PaymentForWallet extends StatelessWidget {
  PaymentForWallet({super.key, this.totalAmount = 0.0, this.title = "Wallet"});
  var option = ''.obs;
  final double totalAmount;
  final String title;
  final WalletController walletController = Get.put(WalletController());

  @override
  Widget build(BuildContext context) {
    walletController.fetchWallet();

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
            _buildPaymentSummary(context,),

            // UPI Section
            Text(
              "UPI",
              style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ).paddingSymmetric(horizontal: Get.width * 0.05),

            _buildUPIOptions(context),

            SizedBox(height: Get.height * 0.03),
            //
            // // Credit & Debit Cards Section
            // Text(
            //   "Credit & Debit Cards",
            //   style: Theme.of(context).textTheme.headlineLarge!.copyWith(
            //     fontWeight: FontWeight.w600,
            //   ),
            // ).paddingSymmetric(horizontal: Get.width * 0.05),
            //
            // SizedBox(height: Get.height * 0.02),
            //
            // _buildCardOptions(context),
            //
            // SizedBox(height: Get.height * 0.03),
          ],
        ),
      ),
      // bottomNavigationBar: _buildPaymentButton(context, cartController),
    );
  }

  Widget _buildPaymentSummary(BuildContext context,) {
    return Container(
      margin: EdgeInsets.all(Get.width * 0.05),
      padding: EdgeInsets.all(Get.width * 0.05),
      decoration: BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Obx(() => Column(
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
          _buildSummaryRow(context, "Less: Wallet Balance", "- ₹${formatAmount(walletController.walletBalance.value.toString())}", true),
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
                  "₹${formatAmount((totalAmount - walletController.walletBalance.value).toString())}",
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      )),
    );
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
            option.value = value;
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
                      groupValue: option.value,
                      onChanged: (val) {
                        option.value = val!;
                      },
                      activeColor: AppColors.primaryColor,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: hasButton && option.value == value
                      ? Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final amountToPay = totalAmount - walletController.walletBalance.value;
                          if (amountToPay <= 0) {
                            Get.snackbar("Error", "Amount cannot be zero or negative");
                            return;
                          }
                          walletController.createBalance(amountToPay);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Obx(() => walletController.isAddingBalance.value
                            ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          "Pay using ${title}",
                          style: TextStyle(
                            color: AppColors.whiteColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        )),
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

}