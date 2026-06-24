import 'package:padel_mobile/presentations/booking/widgets/booking_exports.dart';

class ConfirmCancellation extends StatelessWidget {
  const ConfirmCancellation({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          confirmCancelContent(context),
          PrimaryButton(
            onTap: () {
              Get.toNamed(RoutesName.bottomNav);
            },
            text: AppStrings.continueText,
          ).paddingOnly(bottom: Get.height * 0.05),
        ],
      ).paddingOnly(left: Get.width * 0.05, right: Get.width * 0.05),
    );
  }

  Widget confirmCancelContent(BuildContext context) {
    return Column(
      children: [
        Center(
          child: SvgPicture.asset(Assets.images.imgBookingConfirm.path, height: 200),
        ).paddingOnly(top: Get.height * 0.15, bottom: Get.height * 0.03),
        Text(
          AppStrings.confirmCancellation,
          style: Theme.of(context).textTheme.titleMedium,
        ).paddingOnly(bottom: Get.height * 0.02),
        Text(
          AppStrings.youWillReceiveRefund,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium!.copyWith(fontWeight: FontWeight.w400),
        ).paddingOnly(bottom: Get.height * 0.02),
        Text(
          AppStrings.viewStatus,
          style: Theme.of(context).textTheme.headlineMedium!.copyWith(
            color: AppColors.primaryColor,
            decoration: TextDecoration.underline,
            decorationColor:
                AppColors.primaryColor,
          ),
        ).paddingOnly(bottom: Get.height * 0.02),
      ],
    );
  }
}
