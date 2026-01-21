import '../../widgets/booking_exports.dart';

class AddPlayerBottomSheet extends StatelessWidget {
  final AddPlayerController controller = Get.put(AddPlayerController());
  final Map<String, dynamic>? arguments;
  
  AddPlayerBottomSheet({super.key, this.arguments}) {
    // Initialize controller with arguments
    if (arguments != null) {
      controller.initializeWithArguments(arguments!);
    }
  }

  static void show(BuildContext context, {Map<String, dynamic>? arguments}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddPlayerBottomSheet(arguments: arguments),
    ).whenComplete(() {
      // Clear text fields when bottom sheet is closed
      final controller = Get.find<AddPlayerController>();
      controller.clearTextFields();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          height: Get.height * 0.45,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Text(
              "Add Guest",
              style: Get.textTheme.headlineMedium!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ).paddingOnly(bottom: 11),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  child: Obx(() => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      textFieldWithLabel(
                        "Enter Phone Number",
                        labelText: "Phone Number *",
                        controller.phoneController,
                        context,
                        action: TextInputAction.next,
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                        readOnly: controller.isLoginUserAdding.value,
                        onChanged: (value) {
                          if (value.length < 10) {
                            controller.resetNameField();
                          }
                          if (value.length == 10) {
                            FocusManager.instance.primaryFocus?.unfocus();
                            controller.getUserDataFromNumber(value);
                          }
                        },
                      ),
                      textFieldWithLabel(
                        "Enter Name",
                          labelText: "Name *",
                        textCapitalization: TextCapitalization.words,
                        controller.nameController,
                        context,
                        action: TextInputAction.next,
                        keyboardType: TextInputType.text,
                        readOnly: controller.isLoginUserAdding.value || controller.isNameFromApi.value,
                        color:  controller.isLoginUserAdding.value || controller.isNameFromApi.value?Colors.grey.shade200:AppColors.textFieldColor
                      ),
                      textFieldWithLabel(
                        "Enter Email",
                        labelText: "Email (Optional)",
                        controller.emailController,
                        context,
                        action: TextInputAction.next,
                        keyboardType: TextInputType.emailAddress,
                        readOnly: controller.isLoginUserAdding.value,
                      ),
                    ],
                  )),
                ),
              ),
            ),
            // Bottom button
            bottomBar(context),
          ],
        ),
      ),
    ));
  }

  Widget bottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Obx(
        () => PrimaryButton(
          height: 50,
          onTap: () {
            controller.createUser();
          },
          text: controller.isLoginUserAdding.value ? "Add Me" : "Add Guest",
          child: controller.isLoading.value
              ? const AppLoader(size: 30, strokeWidth: 5)
              : null,
        ).paddingOnly(bottom: 20),
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
        TextCapitalization? textCapitalization,
        dynamic Function(String)? onChanged,
        Color? color,
        String? labelText

      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text(
        //   label,
        //   style: Get.textTheme.headlineSmall!.copyWith(
        //     fontWeight: FontWeight.w600,
        //     color: AppColors.labelBlackColor,
        //   ),
        // ).paddingOnly(top: Get.height * .01),
        PrimaryTextField(
          hintText: label,
          labelText: labelText,
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          action: action,
          textCapitalization: textCapitalization,
          maxLength: maxLength,
          onChanged: onChanged,
          color: color,
        ).paddingOnly(top: 20),
      ],
    );
  }
}
