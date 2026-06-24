import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/app_strings.dart';
import 'package:padel_mobile/configs/components/app_bar.dart';
import 'package:padel_mobile/configs/components/primary_button.dart';
import 'package:padel_mobile/generated/assets.dart';
import 'package:padel_mobile/presentations/bookinghistory/booking_review/booking_completed_review_controller.dart';

class BookingCompletedReview extends StatelessWidget {
  final BookingCompletedReviewController controller = Get.put(BookingCompletedReviewController());
   BookingCompletedReview({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: primaryAppBar(
          centerTitle: true,
          title: Text("Booking Confirmation"), context: context),
      body: SingleChildScrollView(
        child: Column(
          children: [
            successImage(),
            slotDetails(context),
            paymentDetails(context),
            ratingCourt()
          ],
        ).paddingSymmetric(horizontal: Get.width * 0.05),
      ),
    );
  }
  Widget successImage() {
    return Center(
      child: SvgPicture.asset(Assets.images.imgBookingConfirm.path),
    ).paddingOnly(top: Get.height * 0.04, bottom: Get.height * 0.03);
  }
  Widget slotDetails(BuildContext context) {
    return Container(
      width: Get.width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.searchBarColor.withAlpha(80),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.blackColor.withAlpha(10)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SvgPicture.asset(Assets.images.icCelebration.path).paddingOnly(right: 10),
                      Text(
                        "You Played very well",
                        style: Get.textTheme.labelLarge!
                            .copyWith(color: AppColors.labelBlackColor),
                      ),
                    ],
                  ).paddingOnly(bottom: 5),
                  Text(
                      "Your Slots are Successfully booked.",
                      style: Get.textTheme.labelMedium!
                          .copyWith(fontWeight: FontWeight.w400,fontSize: 9),
                  ),
                ],
              ),
            ],
          ).paddingOnly(bottom: Get.height * 0.01),
          infoRow(AppStrings.courtName, "Padel Haus", context),
          infoRow(AppStrings.courtNumber, "2 Court", context),
          infoRow(AppStrings.dateAndTime, "29/06/2025  8:00am (60min)", context),
        ],
      ),
    ).paddingOnly(bottom: Get.height * 0.02);
  }
  Widget infoRow(String label, String value, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: Get
                .textTheme
                .headlineSmall!
                .copyWith(color: AppColors.textColor)),
        Text(value,
            style: Get
                .textTheme
                .headlineSmall!
                .copyWith(color: AppColors.labelBlackColor,fontWeight: FontWeight.w600)),
      ],
    ).paddingOnly(bottom: Get.height * 0.01);
  }
  Widget paymentDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.paymentDetails,
            style: Get
                .textTheme
                .headlineMedium!
                .copyWith(color: AppColors.labelBlackColor))
            .paddingOnly(bottom: Get.height * 0.01),
        infoRow(AppStrings.paymentMethod, "Gpay", context).paddingOnly(left: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppStrings.totalPayment,
                style: Get.textTheme.headlineSmall!.copyWith(
                    color: AppColors.textColor,
                    fontWeight: FontWeight.w500)),
            RichText(
              text: TextSpan(
                style: Get.textTheme.titleMedium!.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(
                    text: '₹',
                    style: TextStyle(
                      fontFamily: "Roboto",
                    ),
                  ),
                  TextSpan(
                    text: ' 1200',
                  ),
                ],
              ),
            )
          ],
        ).paddingOnly(left: 10),
      ],
    ).paddingOnly(bottom: Get.height*0.01);
  }
  Widget ratingCourt(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Rate this court (Padel Haus)", style: Get.textTheme.headlineMedium!.copyWith(color: AppColors.labelBlackColor))
            .paddingOnly(bottom: Get.height * 0.02),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Obx(() => RatingBar.builder(
              itemSize: 30,
              initialRating: controller.rating.value,
              minRating: 0,
              unratedColor: AppColors.starUnselectedColor,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemPadding: EdgeInsets.zero,
              itemBuilder: (context, _) => Container(
                width: 5.0,
                height: 30.0,
                alignment: Alignment.center,
                child: Icon(
                  Icons.star,
                  size: 27.0,
                  color: AppColors.secondaryColor,
                ),
              ),
              onRatingUpdate: (rating) {
                controller.updateRating(rating);
              },
            )).paddingOnly(right: Get.width * 0.05),
            Text(
              "4.5",
              style: Get.textTheme.titleSmall!.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.labelBlackColor,
              ),
            )
          ],
        ),
        Text(
          "Write a message",
          style: Get.textTheme.labelLarge!.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.labelBlackColor,
          ),
        ).paddingOnly(bottom: Get.height * 0.01),
        Container(
          decoration: BoxDecoration(
            color:AppColors.searchBarColor.withAlpha(80),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          padding: const EdgeInsets.all(10),
          child: TextField(
            maxLines: 4,
            scrollPadding: EdgeInsets.only(bottom: Get.height*0.3),
            style: Get.textTheme.bodyLarge!.copyWith(color: AppColors.textColor),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.searchBarColor.withAlpha(0),
              border: InputBorder.none,
              hintStyle: Get.textTheme.bodyLarge!.copyWith(color: AppColors.textColor),
              hintText: 'Write Here',
            ),
          ),
        ).paddingOnly(bottom: Get.height*0.02),
        Center(
          child: PrimaryButton(
              height: Get.height*0.05,
              width: Get.width*0.6,
              onTap: ()=>Get.back(), text: "Submit"),
        )
      ],
    );
  }
}
