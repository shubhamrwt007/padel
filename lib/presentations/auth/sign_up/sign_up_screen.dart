// SignUpScreen.dart
import 'package:flutter/cupertino.dart';
import 'package:padel_mobile/presentations/auth/sign_up/widgets/sign_up_exports.dart';

import '../../../handler/text_formatter.dart';

class SignUpScreen extends GetView<SignUpController> {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: PrimaryContainer(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: primaryAppBar(title: const SizedBox(), context: context),
          body: SingleChildScrollView(
            child: Column(
              children: [
                topTexts(context),
                formFields(),
                genderField(),
                locationField(),
                bottomButtonAndContent(context),
              ],
            ).paddingOnly(left: Get.width * 0.05, right: Get.width * 0.05),
          ),
        ),
      ),
    );
  }

  Widget topTexts(BuildContext context) {
    return Column(
      children: [
        Text(
          "Create Account",
          style: Get.textTheme.titleLarge,
        ).paddingOnly(bottom: Get.height * 0.02, top: Get.height * 0.02),
        Text(
          "Create an account so you can start booking.",
          style: Get.textTheme.headlineMedium!
              .copyWith(fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ).paddingOnly(bottom: Get.height * 0.06),
      ],
    );
  }

  Widget formFields() {
    return Form(
      key: controller.formKey,
      child: Column(
        children: [
          PrimaryTextField(
            keyboardType: TextInputType.phone,
            action: TextInputAction.next,
            maxLength: 10,
            formatter: [PhoneNumberInputFormatter()],
            onFieldSubmitted: (v) => controller.onFieldSubmit(),
            controller: controller.phoneController,
            focusNode: controller.phoneFocusNode,
            validator: (v) => controller.validatePhone(),
            hintText: "Enter Phone Number",
            labelText: "Phone Number *",
          ).paddingOnly(bottom: Get.height * 0.03),
          PrimaryTextField(
            keyboardType: TextInputType.text,
            action: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            onFieldSubmitted: (v) => controller.onFieldSubmit(),
            controller: controller.nameController,

            hintText: "Enter Name",
            labelText: "Name *",
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return "Name is required";
              }
              return null;
            },
          ).paddingOnly(bottom: Get.height * 0.03),

          // PrimaryTextField(
          //   keyboardType: TextInputType.name,
          //   action: TextInputAction.next,
          //   onFieldSubmitted: (v) => controller.onFieldSubmit(),
          //   controller: controller.lastNameController,
          //   hintText: "Last Name",
          //   validator: (v) {
          //     if (v == null || v.trim().isEmpty) {
          //       return "Last name is required";
          //     }
          //     return null;
          //   },
          // ).paddingOnly(bottom: Get.height * 0.03),


          PrimaryTextField(
            keyboardType: TextInputType.emailAddress,
            action: TextInputAction.next,
            onFieldSubmitted: (v) => controller.onFieldSubmit(),
            // validator: (v) => controller.validateEmail(),
            controller: controller.emailController,
            focusNode: controller.emailFocusNode,
            hintText: "Enter Email",
            labelText: "Email (Optional)",
          ).paddingOnly(bottom: Get.height * 0.03),

          // Focus(
          //   onFocusChange: (hasFocus) {
          //     controller.isPasswordFocused.value = hasFocus;
          //   },
          //   child: PrimaryTextField(
          //     keyboardType: TextInputType.visiblePassword,
          //     action: TextInputAction.next,
          //     onChanged: (v) => controller.checkPasswordConditions(v),
          //     onFieldSubmitted: (v) => controller.onFieldSubmit(),
          //     validator: (v) => controller.validatePassword(),
          //     controller: controller.passwordController,
          //     hintText: "Password",
          //     obscureText: controller.isVisiblePassword.value,
          //     maxLine: 1,
          //     suffixIcon: IconButton(
          //       onPressed: () => controller.passwordToggle(),
          //       icon: Image.asset(
          //         controller.isVisiblePassword.value
          //             ? Assets.imagesIcEyeOff
          //             : Assets.imagesIcEye,
          //         color: AppColors.textColor,
          //         height: 20,
          //         width: 20,
          //       ),
          //     ),
          //   ),
          // ).paddingOnly(bottom: controller.isPasswordFocused.value? 0: Get.height * 0.03),

          Obx(() {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                // Fade + slight slide from top
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.1),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: controller.isPasswordFocused.value
                  ? Column(
                key: const ValueKey("conditions"),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPasswordCondition(
                    "At least 1 Capital Letter",
                    controller.hasCapitalLetter.value,
                  ),
                  _buildPasswordCondition(
                    "At least 1 Special Character",
                    controller.hasSpecialChar.value,
                  ),
                  _buildPasswordCondition(
                    "At least 1 Number",
                    controller.hasNumber.value,
                  ),
                ],
              )
                  : const SizedBox.shrink(
                key: ValueKey("empty"),
              ),
            );
          }),

        ],
      ),
    );
  }
  Widget _buildPasswordCondition(String text, bool value) {
    return Row(
      children: [
        Transform.scale(
          scale: 0.8,
          child: Checkbox(
            value: value,
            onChanged: null,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            fillColor: WidgetStateProperty.resolveWith<Color>(
                  (states) {
                if (value) return Colors.green;
                return Colors.grey.shade50;
              },
            ),
            checkColor: Colors.white,
          ),
        ),
        Text(
          text,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget locationField() {
    final style = Get.textTheme.headlineMedium!.copyWith(color: AppColors.textColor,fontWeight: FontWeight.w500);
    return  Obx(() {
            if (controller.isLocationLoading.value) {
              return Container(
                height: 52,
                width: Get.width,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.textFieldColor,
                  border: Border.all(color: Colors.grey,width: 1),
                  borderRadius: BorderRadius.circular(5),

                ),
                child: Row(
                  children: [
                    CupertinoActivityIndicator(color: AppColors.primaryColor,radius: 14,).paddingOnly(right: 5,left: 10),
                    Text("Loading Locations...",style: style,),
                  ], 
                ),
              );
            }

            if (controller.locations.isEmpty) {
              return Container(
                height: 52,
                width: Get.width,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.textFieldColor,
                  border: Border.all(color: Colors.grey,width: 1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text("No Location found",style: style,),
              );
            }

            return GestureDetector(
              onTap: () => _showLocationDialog(),
              child: Container(
                height: 52,
                width: Get.width,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.textFieldColor,
                  border: Border.all(color: Colors.grey,width: 1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      controller.selectedLocation.value.isEmpty
                          ? "Preferred Location *"
                          : controller.selectedLocation.value,
                      style: style.copyWith(
                        color: controller.selectedLocation.value.isEmpty
                            ? Colors.grey.shade600
                            : AppColors.textColor,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                  ],
                ),
              ),
            );

          }).paddingOnly(bottom: Get.height * 0.12);
  }

  void _showLocationDialog() {
    final searchController = TextEditingController();
    final filteredLocations = <dynamic>[].obs;
    filteredLocations.addAll(controller.locations);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Container(
          height: Get.height * 0.6,
          width: Get.width * 0.9,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                "Select Location",
                style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Search cities...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  filteredLocations.clear();
                  if (value.isEmpty) {
                    filteredLocations.addAll(controller.locations);
                  } else {
                    filteredLocations.addAll(
                      controller.locations.where((location) =>
                          location.name?.toLowerCase().contains(value.toLowerCase()) ?? false),
                    );
                  }
                },
              ),
              const SizedBox(height: 5),
              Expanded(
                child: Obx(() => ListView.builder(
                  itemCount: filteredLocations.length,
                  itemBuilder: (context, index) {
                    final location = filteredLocations[index];
                    return ListTile(
                      title: Text(location.name ?? ''),
                      onTap: () {
                        controller.selectedLocation.value = location.name ?? '';
                        controller.selectedLocationId.value = location.id ?? '';
                        Get.back();
                      },
                    );
                  },
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
  

  Widget genderField() {
    final style = Get.textTheme.headlineMedium!.copyWith(color: AppColors.textColor,fontWeight: FontWeight.w500);
    return Container(
      height: 52,
      width: Get.width,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.textFieldColor,
        border: Border.all(color: Colors.grey,width: 1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: DropdownButtonHideUnderline(
        child: Obx(
          () => DropdownButton<String>(
            value: controller.selectedGender.value.isEmpty
                ? null
                : controller.selectedGender.value,
            hint: Text("Select Gender *", style: style),
            dropdownColor: Colors.white,
            isExpanded: true,
            items: controller.genderOptions
                .map((gender) => DropdownMenuItem<String>(
              value: gender,
              child: Text(
                gender,
                style: style,
              ),
            ))
                .toList(),
            onChanged: (value) {
              controller.selectedGender.value = value ?? "";
            },
          ),
        ),
      ),
    ).paddingOnly(bottom: Get.height * 0.03);
  }
  Widget bottomButtonAndContent(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            Get.offNamed(RoutesName.login);
          },
          child: Container(
            color: Colors.transparent,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "Already have an account? ",
                    style: Get.textTheme.headlineMedium!.copyWith(
                      color: AppColors.darkGreyColor,
                    ),
                  ),
                  TextSpan(
                    text: "Sign In",
                    style: Get.textTheme.headlineMedium!.copyWith(
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).paddingOnly(bottom: Get.height * 0.03),
        Obx(
              () => PrimaryButton(
            onTap: () async {
              await controller.onCreate();
            },
            text: "Create",
            child: controller.isLoading.value
                ? AppLoader(size: 35, strokeWidth: 4)
                : null,
          ),
        ),
        SizedBox(height: Get.height * 0.04),
      ],
    );
  }
}
