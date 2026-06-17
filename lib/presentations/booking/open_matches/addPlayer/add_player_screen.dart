import 'package:flutter/services.dart';
import '../../../../configs/components/safe_bottom_container.dart';
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
    return SafeBottomContainer(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      child: GestureDetector(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          controller.showNameDropdown.value = false;
        },
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            height: Get.height * 0.55,
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
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Obx(() => textFieldWithLabel(
                              "Enter Phone Number",
                              labelText: "Phone Number *",
                              controller.phoneController,
                              context,
                              action: TextInputAction.next,
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              readOnly: controller.isLoginUserAdding.value || controller.isPhoneFromApi.value,
                              color: controller.isLoginUserAdding.value || controller.isPhoneFromApi.value ? Colors.grey.shade200 : AppColors.textFieldColor,
                              onChanged: (value) {
                                if (value.length < 10) {
                                  controller.resetNameField();
                                }
                                if (value.length == 10) {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  controller.getUserDataFromNumber(value);
                                }
                              },
                            )),
                            Obx(() => textFieldWithLabel(
                              "Enter Name",
                              labelText: "Name *",
                              textCapitalization: TextCapitalization.words,
                              controller.nameController,
                              context,
                              action: TextInputAction.next,
                              keyboardType: TextInputType.text,
                              readOnly: controller.isLoginUserAdding.value || controller.isNameFromApi.value,
                              color: controller.isLoginUserAdding.value || controller.isNameFromApi.value ? Colors.grey.shade200 : AppColors.textFieldColor,
                              onChanged: (value) {
                                if (value.length < 2) {
                                  controller.resetPhoneField();
                                }
                                controller.searchUserByName(value);
                              },
                            )),
                            _genderSelection(context),
                            Obx(() => textFieldWithLabel(
                              "Enter Email",
                              labelText: "Email (Optional)",
                              controller.emailController,
                              context,
                              action: TextInputAction.next,
                              keyboardType: TextInputType.emailAddress,
                              readOnly: controller.isLoginUserAdding.value || controller.isEmailFromApi.value,
                              color: controller.isLoginUserAdding.value || controller.isEmailFromApi.value ? Colors.grey.shade200 : AppColors.textFieldColor,
                            )),
                          ],
                        ),
                      ),
                      // Dropdown overlay
                      Obx(() {
                        if (controller.showNameDropdown.value && controller.nameSearchResults.isNotEmpty) {
                          return Positioned(
                            top: 150, // Adjusted position below name field
                            left: 0,
                            right: 0,
                            child: Material(
                              elevation: 8,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                constraints: BoxConstraints(maxHeight: 200),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  physics: AlwaysScrollableScrollPhysics(),
                                  itemCount: controller.nameSearchResults.length,
                                  itemBuilder: (context, index) {
                                    final user = controller.nameSearchResults[index];
                                    return InkWell(
                                      onTap: () => controller.selectUserFromDropdown(user),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: index < controller.nameSearchResults.length - 1
                                                  ? Colors.grey.shade200
                                                  : Colors.transparent,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                user['name'] ?? '',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              user['maskedPhoneNumber'] ?? '',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        }
                        return SizedBox.shrink();
                      }),
                    ],
                  ),
                ),
              ),
              // Bottom button
              bottomBar(context),
            ],
          ),
        ),
      )),
    );
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
                onTap: controller.isGenderFromApi.value ? null : () => controller.gender.value = gender,
                child: Row(
                  children: [
                    Icon(
                      controller.gender.value == gender
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      size: 15,
                      color: controller.isGenderFromApi.value ? Colors.grey : Colors.black,
                    ),
                    Text(
                      gender,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall!.copyWith(
                        fontSize: 14,
                        color: controller.isGenderFromApi.value ? Colors.grey : Colors.black,
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
        String? labelText,
        List<TextInputFormatter>? inputFormatters,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          formatter: inputFormatters,
        ).paddingOnly(top: 20),
      ],
    );
  }
}
