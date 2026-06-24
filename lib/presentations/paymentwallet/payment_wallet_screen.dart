import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';
import 'package:padel_mobile/handler/text_formatter.dart';
import 'package:padel_mobile/presentations/paymentwallet/payment_wallet_controller.dart';
import 'package:padel_mobile/presentations/paymentwallet/widgets/custom_skeleton_loder.dart';
import 'package:shimmer/shimmer.dart';

import '../../configs/app_colors.dart';
import '../../configs/components/app_bar.dart';
import '../../generated/assets.dart';

class PaymentWalletScreen extends StatelessWidget {
  final PaymentWalletController controller = Get.put(PaymentWalletController());
  PaymentWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: primaryAppBar(
        showLeading: true,
        centerTitle: true,
        title: Text("Transactions").paddingOnly(left: Get.width * 0.02),
        context: context,
      ),
      body: RefreshIndicator(
        edgeOffset: 1,
        displacement: Get.width * .2,
        color: AppColors.whiteColor,
        onRefresh: () async {
        await controller.fetchPaymentDetails();
        },
        child: Column(
          children: [
            myWallet(),
            filterRow(),
            Obx((){
              if(controller.isLoading.value){
                return Expanded(
                  child: ListView.separated(
                    itemCount: 10,
                    separatorBuilder: (BuildContext context, int index)=>Divider(color: Colors.grey.shade200,),
                    itemBuilder: (context,index) {
                      return paymentTileShimmer();
                    },
                  ),
                );
              }
              if(controller.paymentList.isEmpty){
                return Expanded(child: Center(child: Text("No Payment Details")));
              }
              return Expanded(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: controller.paymentList.length,
                  separatorBuilder: (BuildContext context, int index)=>Divider(color: Colors.grey.shade200,),
                  itemBuilder: (context, index) {
                    final payment = controller.paymentList[index];
                    final clubName = payment.registerClubId?.clubName??"N/A";
                    final bookingDate = payment.bookingDate??"N/A";
                    final slot = payment.slot?[0].slotTimes?[0].time??"0";
                    final courtName = payment.slot?[0].courtName??"";
                    final amount = (payment.slot?[0].slotTimes?[0].amount??"0").toString();
                    return paymentTiles(clubName: clubName,bookingDate: bookingDate,slot: slot,amount: amount,courtName: courtName);
                  },
                ),
              );
            })

            ///
          ],
        ).paddingSymmetric(horizontal: Get.width * .05,vertical: Get.height*.01),
      ),
    );
  }
  Widget myWallet(){
    return GestureDetector(
      onTap: ()=>Get.toNamed(RoutesName.wallet),
      child: Container(
        width: Get.width,
        padding: EdgeInsets.symmetric(vertical: 10,horizontal: Get.width*0.03),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0x99d5dcf1),
              Color(0x99dbf1e3),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.lightBlueColor.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      Assets.images.icBalanceWallet.path,
                      scale: 5,
                    ),
                    Text(
                      "My Wallet",
                      style: Get.textTheme.headlineSmall!.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: AppColors.labelBlackColor,
                      ),
                    ).paddingOnly(left: 5),
                  ],
                ),
                Text(
                  "Available balance",
                  style: Get.textTheme.bodyLarge!.copyWith(
      
                    color: AppColors.labelBlackColor,
                  ),
                ).paddingOnly(top: 5),
              ],
            ),
           Row(
             children: [
               Obx(() => (controller.walletController.isWalletLoading.value || controller.walletController.walletBalance.value == null)
                 ? Shimmer.fromColors(
                     baseColor:  Color(0x99d5dcf1),
                     highlightColor:  Color(0x99dbf1e3),
                     child: Container(
                       height: 20,
                       width: 80,
                       decoration: BoxDecoration(
                         color: Colors.white,
                         borderRadius: BorderRadius.circular(4),
                       ),
                     ),
                   )
                 : Text(
                     formatAmount(controller.walletController.walletBalance.value.toString()),
                     style: Get.textTheme.titleMedium!.copyWith(
                       color: AppColors.primaryColor,
                     ),
                   )),
               Text(
                 " Credits",
                 style: Get.textTheme.titleMedium!.copyWith(
                     color: AppColors.primaryColor,
                     fontSize: 15,
                     fontFamily: "Roboto"
                 ),
               ).paddingOnly(top: 2,right: 40),
               Icon(Icons.arrow_forward_ios,size: 22,color: AppColors.textColor,)
             ],
           )
          ],
        ),
      ),
    );
  }
  Widget filterRow(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "All Payment",
          style: Get
              .textTheme
              .bodyMedium!
              .copyWith(
            ///////
            color: AppColors.blackColor,
          ),
        ),
        // GestureDetector(
        //   onTap: (){
        //     Get.toNamed(RoutesName.paymentFilter);
        //   },
        //   child: Container(height: 28,width: 32,
        //     decoration: BoxDecoration(
        //         color: AppColors.tabSelectedColor,
        //         borderRadius: BorderRadius.circular(8)
        //
        //     ),
        //     child: Image.asset(
        //       Assets.images.icFilter.path,
        //       scale: 5,
        //     ),
        //   ),
        // ) ,
      ],
    ).paddingOnly(top: 15,bottom: 15);
  }
  Widget paymentTiles({required String clubName,required String bookingDate,required String slot,required String amount,required String courtName}){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          clubName,
          style: Get
              .textTheme
              .labelLarge!
              .copyWith(
            color: AppColors.blackColor,
          ),
        ),
        Row(
          children: [
            Text(
              controller.formatDate(bookingDate),
              style: Get.textTheme.bodySmall!.copyWith(
                fontWeight: FontWeight.w400,
                color: AppColors.labelBlackColor,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              slot,
              style: Get.textTheme.bodySmall!.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.labelBlackColor,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              "( $courtName )",
              style: Get.textTheme.bodySmall!.copyWith(
                fontWeight: FontWeight.w400,
                color: AppColors.labelBlackColor,
              ),
            ),
            const Spacer(),
            Text(
              "₹",
              style:Get.textTheme.headlineMedium!.copyWith(
                fontFamily: "Roboto",
                color: AppColors.blueColor,
                fontWeight: FontWeight.w500,
              ),
            ).paddingOnly(top: 2),
            const SizedBox(width: 2),
            Text(
              formatAmount(amount),
              style: Get
                  .textTheme
                  .headlineMedium!
                  .copyWith(
                color: AppColors.blueColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ).paddingOnly(top: 5),
      ],
    );
  }
}
