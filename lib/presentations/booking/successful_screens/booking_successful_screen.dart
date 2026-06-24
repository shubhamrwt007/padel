import 'package:padel_mobile/presentations/booking/widgets/booking_exports.dart';
import 'package:padel_mobile/presentations/bookinghistory/booking_history_screen.dart';
import 'package:padel_mobile/presentations/home/home_controller.dart';

import '../../payment/payment_method_controller.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';
import 'package:padel_mobile/presentations/americano/americano_controller.dart';

class BookingSuccessfulScreen extends StatelessWidget {
  final String? buttonType;
  const BookingSuccessfulScreen({super.key,this.buttonType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Center(
            child: Image.asset(Assets.images.imgBookingSuccessful.path, scale: 4),
          ).paddingOnly(top: Get.height * 0.2,bottom: Get.height*0.02),
          Text(
            buttonType== "tournament"?"Registration Complete":AppStrings.bookingSuccessful,
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              color: AppColors.blackColor,
              fontWeight: FontWeight.w600,
            ),
          ).paddingOnly(bottom: Get.height * 0.02),
          Text(
            buttonType == "tournament"?"Your Registration complete successfully.":AppStrings.yourSlotBooked,
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
              color: AppColors.blackColor,
              fontWeight: FontWeight.w400,
            ),
          ).paddingOnly(bottom: Get.height * 0.05),
          PrimaryButton(
            onTap: () {
              if (Get.isRegistered<PaymentMethodController>()) {
                Get.delete<PaymentMethodController>(force: true);
              }
              if (buttonType == "tournament") {
                Get.offAllNamed(RoutesName.bottomNav);
                Get.toNamed(RoutesName.americano);
              } else {
                Get.offAllNamed(RoutesName.bottomNav);
              }
            },
            text: AppStrings.continueText,
          ).paddingOnly(bottom: Get.height * 0.14),
          Text(
            AppStrings.youWillReceiveReminder,
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
              color: AppColors.blackColor,
              fontWeight: FontWeight.w400,
            ),
          ).paddingOnly(bottom: Get.height * 0.02),
          if(buttonType=="")
            GestureDetector(
            onTap: () => Get.to(BookingHistoryUi(buttonType: "drawer",)),
            child: Container(
              color: Colors.transparent,
              child: Text(
                AppStrings.viewBookingDetails,
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  color: AppColors.primaryColor,
                ),
              ).paddingOnly(bottom: Get.height * 0.06),
            ),
          ),
          Text(
            "Powered By RowthTech",
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
              color: AppColors.blackColor,
              fontWeight: FontWeight.w400,fontSize: 12,
            ),
          )
        ],
      ).paddingOnly(left: Get.width * 0.05, right: Get.width * 0.05),
    );
  }
}
