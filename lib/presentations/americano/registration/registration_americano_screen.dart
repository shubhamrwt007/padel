import 'package:padel_mobile/configs/components/safe_scaffold.dart';
import 'package:padel_mobile/handler/text_formatter.dart';
import 'package:padel_mobile/presentations/americano/widgets/americano_exports.dart';

import '../../booking/successful_screens/booking_successful_screen.dart';

class RegistrationAmericanoScreen extends GetView<RegistrationAmericanoController> {
  const RegistrationAmericanoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus!.unfocus(),
      child: SafeScaffold(
        bottomNavigationBar: bottomBar(context),
        appBar: primaryAppBar(
          centerTitle: true,
          title: Text("Registration"),
          context: context,
        ),
        body: _buildForm(context,)
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            textFieldWithLabel(
              "Full Name",
              action: TextInputAction.next,
              controller.fullNameController,
              context,
              validator: (v)=>validateName(controller.fullNameController.text.trim()),
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.words
            ),
            textFieldWithLabel(
              "Email",
              action: TextInputAction.next,
              controller.emailController,
              context,
              validator: (v)=>validateEmail(controller.emailController.text.trim()),
              keyboardType: TextInputType.emailAddress
            ),
            textFieldWithLabel(
              "Phone Number",
              action: TextInputAction.next,
              controller.phoneController,
              context,
              maxLength: 10,
              validator: (v)=>validatePhone(controller.phoneController.text.trim()),
              keyboardType: TextInputType.number
            ).paddingOnly(bottom: Get.height * 0.015),

            _genderSelection(context)
          ],
        ),
      ),
    );
  }
  Widget bottomBar(BuildContext context) {
    return Container(
      height: Get.height * .12,
      padding: const EdgeInsets.only(top: 10),
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
      child: Center(
        child: Container(
          height: 55,
          width: Get.width * 0.9,
          decoration: BoxDecoration(
            color: AppColors.whiteColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: PrimaryButton(
            height: 50,
            onTap: () {
              Get.to(() => BookingSuccessfulScreen(
                buttonType: "tournament",
              ));
            },
            text: "Continue",
          ),
        ).paddingOnly(bottom: Get.height * 0.03),
      ),
    );
  }

  Widget textFieldWithLabel(
      String label,
      TextEditingController? controller,
      BuildContext context, {
        bool readOnly = false,
        TextInputType? keyboardType,
        TextInputAction? action,
        int? maxLength,
        String? Function(String?)? validator,
        TextCapitalization? textCapitalization
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10,),
        Text(label,style: Get.textTheme.bodySmall!.copyWith(color: Colors.black),),
        PrimaryTextField(
          hintText: "Enter $label",
          // labelText: label,
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          action: action,
          textCapitalization: textCapitalization,
          maxLength: maxLength,
          validator: validator,
        ).paddingOnly(top: 10),
      ],
    );
  }
  Widget _genderSelection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Gender",
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.labelBlackColor,
          ),
        ).paddingOnly(top: Get.height * .02),
        Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ["Female", "Male", "Other"].map((gender) {
                  return GestureDetector(
                    onTap: () => controller.selectedGender.value = gender,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        Icon(
                          controller.selectedGender.value == gender
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          size: 15,
                          color: Colors.black,
                        ),
                        Text(
                          gender,
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall!.copyWith(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ).paddingOnly(left: 5),
                      ],
                    ),
                  );
                }).toList(),
              ),
        ).paddingOnly(top: 10),
      ],
    );
  }
}