import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../configs/app_colors.dart';
import '../../configs/components/app_bar.dart';
import '../../configs/components/primary_button.dart';
import '../../configs/components/primary_text_feild.dart';
import 'support_controller.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SupportController());

    return Scaffold(
      appBar: primaryAppBar(
        showLeading: true,
        centerTitle: true,
        title: Text(
          " Help & Support",
          style: Theme.of(context).textTheme.titleMedium,
        ).paddingOnly(left: Get.width * 0.02),
        context: context,
      ),
      body: SingleChildScrollView(
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.email_outlined, color: AppColors.labelBlackColor),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Email",
                        style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.labelBlackColor,
                        ),
                      ),
                      SelectableText(
                        "support@rowthtech.com",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ).paddingOnly(left: 10),
                ],
              ),
              Row(
                children: [
                  Icon(CupertinoIcons.phone, color: AppColors.labelBlackColor),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Phone Number",
                        style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.labelBlackColor,
                        ),
                      ),
                      SelectableText(
                        "+91 9115559606",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ).paddingOnly(left: 10),
                ],
              ).paddingOnly(top: 20),
              const SizedBox(height: 30),
              Text(
                "Submit a Request",
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Text("Title",style: TextStyle(fontWeight: FontWeight.w500),).paddingOnly(bottom: 5),

              PrimaryTextField(
                color: AppColors.whiteColor,
                controller: controller.titleController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Title is required";
                  }
                  return null;
                }, hintText: '',
              ),
              const SizedBox(height: 15),
              Text("Description",style: TextStyle(fontWeight: FontWeight.w500),).paddingOnly(bottom: 5),
              PrimaryTextField(
                color: AppColors.whiteColor,

                height: Get.height*.2,
                controller: controller.descriptionController,
                maxLine: 5,
                textCapitalization: TextCapitalization.sentences,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: Get.width * 0.02,
                  vertical: Get.height * 0.01,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Description is required";
                  }
                  return null;
                }, hintText: '',
              ),
              const SizedBox(height: 30),
              Obx(() => PrimaryButton(
                onTap: controller.isLoading.value ? null : controller.submitSupport,
                text: controller.isLoading.value ? "Submitting..." : "Submit",
              )),
            ],
          ).paddingOnly(left: Get.width * .09, right: Get.width * .07, top: 20),
        ),
      ),
    );
  }
}
