

import 'package:padel_mobile/presentations/auth/forgot_password/widgets/forgot_password_exports.dart';

import '../../../../configs/components/loader_widgets.dart';

class ResetPasswordScreen extends GetView<ForgotPasswordController> {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus!.unfocus(),
      child: PrimaryContainer(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: primaryAppBar(title: Text(""), context: context),
          body: resetPassword(context, controller),
        ),
      ),
    );
  }

  Widget resetPassword(
    BuildContext context,
    ForgotPasswordController controller,
  ) {
    return SingleChildScrollView(
      child: Form(
        key: controller.resetFormKey,
        child: Column(
          children: [
            Center(
              child: Text(
                AppStrings.resetPassword,
                style: Theme.of(context).textTheme.titleLarge,
              ).paddingOnly(bottom: Get.height * 0.03, top: Get.height * 0.15),
            ),
            Text(
              AppStrings.enterAndConfirmNewPass,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium!.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ).paddingOnly(bottom: Get.height * 0.05),
            Obx(
              () => PrimaryTextField(
                validator: (v) => controller.validatePassword(),
                controller: controller.pwdController,
                hintText: AppStrings.password,
                obscureText: controller.isVisiblePassword.value,
                maxLine: 1,
                suffixIcon: IconButton(
                  onPressed: () => controller.passwordToggle(),
                  icon: Image.asset(
                    controller.isVisiblePassword.value
                        ? Assets.images.icEyeOff.path
                        : Assets.images.icEye.path,
                    color: AppColors.textColor,
                    height: 24,
                    width: 24,
                  ),
                ),
              ).paddingOnly(bottom: Get.height * 0.03),
            ),
            Obx(
              () =>
                  PrimaryTextField(
                    validator: (v) => controller.validateConfirmPassword(),
                    controller: controller.cnfPwdController,

                    hintText: AppStrings.confirmPassword,
                    obscureText: controller.isVisibleConfirmPassword.value,
                    maxLine: 1,
                    suffixIcon: IconButton(
                      onPressed: () => controller.confirmPasswordToggle(),
                      icon: Image.asset(
                        controller.isVisibleConfirmPassword.value
                            ? Assets.images.icEyeOff.path
                            : Assets.images.icEye.path,
                        color: AppColors.textColor,
                        height: 24,
                        width: 24,
                      ),
                    ),
                  ).paddingOnly(
                    bottom: MediaQuery.of(context).viewInsets.bottom > 0
                        ? Get.height * 0.03
                        : Get.height * 0.29,
                  ),
            ),
            Obx(
              () => PrimaryButton(
                onTap: () {
                  controller.resetPassword();
                },

                text: AppStrings.changePassword,
                child: controller.isLoading.value
                    ? AppLoader(size: 35, strokeWidth: 4)
                    : null,
              ).paddingOnly(bottom: Get.height * 0.03),
            ),
          ],
        ).paddingOnly(left: Get.width * 0.05, right: Get.width * 0.05),
      ),
    );
  }
}
