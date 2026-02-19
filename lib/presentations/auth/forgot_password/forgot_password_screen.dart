import 'package:padel_mobile/configs/components/app_toast.dart';
import 'package:padel_mobile/presentations/auth/forgot_password/widgets/forgot_password_exports.dart';

import '../../../configs/components/loader_widgets.dart';
import '../../../configs/components/snack_bars.dart';

class ForgotPasswordScreen extends GetView<ForgotPasswordController> {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus!.unfocus(),
      child: PrimaryContainer(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: primaryAppBar(title: Text(""), context: context),
          body: forgotPassword(context, controller),
        ),
      ),
    );
  }

  Widget forgotPassword(
    BuildContext context,
    ForgotPasswordController controller,
  ) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Center(
            child: Text(
              AppStrings.forgotPassword,
              style: Theme.of(context).textTheme.titleLarge,
            ).paddingOnly(bottom: Get.height * 0.03, top: Get.height * 0.15),
          ),
          Text(
            AppStrings.letHelpYouBackIn,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium!.copyWith(fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ).paddingOnly(bottom: Get.height * 0.05),
          Form(
            key: controller.formKey,
            child:
                PrimaryTextField(
                  validator: (v) {
                    return controller.validateEmail(v);
                  },
                  controller: controller.emailController,
                  hintText: AppStrings.email,
                ).paddingOnly(
                  bottom: MediaQuery.of(context).viewInsets.bottom > 0
                      ? Get.height * 0.0
                      : Get.height * 0.32,
                ),
          ),
          Obx(
            () => PrimaryButton(
              onTap: () {
                if (controller.formKey.currentState!.validate()) {
                  controller.sendOTP();
                } else {
                  AppToast.error(AppStrings.invalidEmail);
                }
              },
              text: AppStrings.sendOtp,
              child: controller.isOTPLoading.value
                  ? AppLoader(size: 35, strokeWidth: 4)
                  : null,
            ).paddingOnly(bottom: Get.height * 0.03, top: Get.height * 0.06),
          ),
        ],
      ).paddingOnly(left: Get.width * 0.05, right: Get.width * 0.05),
    );
  }
}
