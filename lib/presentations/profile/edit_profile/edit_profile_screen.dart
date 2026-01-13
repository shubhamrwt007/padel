import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:padel_mobile/presentations/profile/widgets/profile_exports.dart';

class EditProfileUi extends StatelessWidget {
  final String? buttonType;
  final EditProfileController controller = Get.put(EditProfileController());
  EditProfileUi({super.key,this.buttonType});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus!.unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.whiteColor,
        bottomNavigationBar: _bottomBar(context),
        appBar: primaryAppBar(
          showLeading:buttonType=="drawer"? true:false,
          centerTitle: true,
          title: Text("Profile").paddingOnly(left: Get.width * 0.02),
          context: context,
        ),
        body: RefreshIndicator(
          color: Colors.white,
          onRefresh: () async {
            await controller.refreshProfile();
          },
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _profileImage(context),
                _textFieldWithLabel(
                  "Name",
                  controller.nameController,
                  context,
                ),
                // _textFieldWithLabel(
                //   "Last Name",
                //   controller.lastNameController,
                //   context,
                // ),
                _textFieldWithLabel(
                  "Email",
                  controller.emailController,
                  context,
                 ),
                _textFieldWithLabel(
                  "Phone",
                  controller.phoneController,
                  context,
                   keyboardType: TextInputType.phone,
                ),
                _genderSelection(context),
                _dobField(context),
                   Text(
            "Location / City",
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.labelBlackColor,
            ),
          ).paddingOnly(top: Get.height * .02,bottom: Get.height*0.01),
                locationField(),
                _statisticsContainer(context)
              ],
            ).paddingOnly(top: 10, left: Get.width * 0.05, right: Get.width * 0.05),
          ),
        ),
      ),
    );
  }

  Widget _bottomBar(BuildContext context) {
    return Container(
      height: Get.height * .12,
      padding: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
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
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Obx(
            () => PrimaryButton(
              height: 50,
              onTap: () {
                controller.updateProfile();
              },
              text: "Update",
              child: controller.isLoading.value
                  ? AppLoader(size: 30, strokeWidth: 5)
                  : null,
            ),
          ),
        ).paddingOnly(bottom: Get.height * 0.03),
      ),
    );
  }

  Widget _profileImage(BuildContext context) {
    return Center(
      child: Obx(() {
        final imagePath = controller.profileImage.value?.path;
        final imageUrl = controller.profileImageUrl.value;

        return Stack(
          alignment: Alignment.bottomRight,
          children: [
            GestureDetector(
              onTap: () => controller.showImageSourceActionSheet(context),
              child: Container(
                height: Get.height * .11,
                width: Get.width * .24,
                decoration: BoxDecoration(
                  color: AppColors.tabSelectedColor,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: ClipOval(
                  child: imagePath != null
                      ? Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                    width: Get.width * .24,
                    height: Get.height * .11,
                  )
                      : imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    width: Get.width * .24,
                    height: Get.height * .11,
                    placeholder: (context, url) => Center(
                      child: LoadingWidget(color: AppColors.primaryColor,),
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.person,
                      size: 90,
                      color: AppColors.labelBlackColor,
                    ),
                  )
                      : Icon(
                    Icons.person,
                    size: 90,
                    color: AppColors.labelBlackColor,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 5,
              child: GestureDetector(
                onTap: () => controller.showImageSourceActionSheet(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.secondaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(Assets.imagesIcCamara, scale: 4.2),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _textFieldWithLabel(
    String label,
    TextEditingController? controller,
    BuildContext context, {
    bool readOnly = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.labelBlackColor,
          ),
        ).paddingOnly(top: Get.height * .02),
        PrimaryTextField(
          hintText: "Enter $label",
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          // scrollPadding: EdgeInsets.only(bottom: Get.height*0.3),
          contentPadding: EdgeInsets.symmetric(
            horizontal: Get.width * 0.04,
            vertical: (57) * 0.22,
          ),
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
                child: Row(
                  children: [
                    Icon(
                      controller.selectedGender.value == gender
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      size: 15,
                      color: AppColors.labelBlackColor,
                    ),
                    Text(
                      gender,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall!.copyWith(fontSize: 14),
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

  Widget _dobField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Date of Birth",
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.labelBlackColor,
          ),
        ).paddingOnly(top: Get.height * .02),
        Obx(
              () => GestureDetector(
               onTap: ()=>controller.selectDate(context),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: Get.width * 0.04,
                vertical: 57 * 0.22,
              ),
              decoration: BoxDecoration(
                color: AppColors.textFieldColor,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.grey,width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    controller.selectedDate.value.isEmpty
                        ? "Select Date of Birth"
                        : controller.selectedDate.value,
                    style: TextStyle(
                      color: controller.selectedDate.value.isEmpty
                          ? AppColors.textHintColor
                          : AppColors.textColor,
                      fontSize: 16,
                    ),
                  ),
                  Icon(
                    Icons.calendar_month_outlined,
                    color: AppColors.iconColor,
                  ),
                ],
              ),
            ).paddingOnly(top: 10),
          ),
        )
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
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.grey,width: 1),
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
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.grey,width: 1),
                ),
                child: Text("No Location found",style: style,),
              );
            }

            return Container(
              height: 52,
              width: Get.width,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.textFieldColor,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.grey,width: 1),
              ),
              child: DropdownButtonHideUnderline(
                child: Obx(
                      () => DropdownButton<String>(
                    value: controller.selectedLocation.value.isEmpty
                        ? null
                        : controller.selectedLocation.value,
                    hint: Text("Pefered Location", style: style),
                    dropdownColor: Colors.white,
                    isExpanded: true,
                    items: controller.locations
                        .map((state) => DropdownMenuItem<String>(
                      value: state.name ?? '',
                      child: Text(
                        state.name ?? '',
                        style: style,
                      ),
                    ))
                        .toList(),
                    onChanged: (value) {
                      controller.selectedLocation.value = value ?? "";
                      CustomLogger.logMessage(msg: "Selected Location -> ${controller.selectedLocation.value}",level: LogLevel.info);
                    },
                  ),
                ),
              ),
            );

          }).paddingOnly(bottom: Get.height * 0.01);
  }

  Widget _statisticsContainer(BuildContext context) {
    return Obx(() {
      final response = controller.profileController.profileModel.value?.response;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Player Statistics",
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.labelBlackColor,
            ),
          ).paddingOnly(top: Get.height * .02),
          Container(
            margin: EdgeInsets.only(top: 10),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.textFieldColor,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: Colors.grey,width: 1),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _statItem("XP Points", "${response?.xpPoints ?? 0}")),
                    // Expanded(child: _statItem("Rank", "${response?.rank ?? 0}")),
                    Expanded(child: _statItem("Win Streak", "${response?.currentWinStreak ?? 0}")),

                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _statItem("Lose Streak", "${response?.currentLoseStreak ?? 0}")),
                    Expanded(child: _statItem("Total Matches", "${response?.totalMatchesPlayed ?? 0}")),

                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _statItem("Total Wins", "${response?.totalWins ?? 0}")),
                  ],
                ),
                SizedBox(height: 12),
                // Row(
                //   children: [
                //     Expanded(child: _statItem("Open Matches", "${response?.openMatchCount ?? 0}")),
                //     Expanded(child: _statItem("American Matches", "${response?.americanMatchCount ?? 0}")),
                //   ],
                // ),
                SizedBox(height: 12),
                // Row(
                //   children: [
                //     Expanded(child: _statItem("Simple Matches", "${response?.simpleMatchCount ?? 0}")),
                //     SizedBox(width: Get.width * 0.45),
                //   ],
                // ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _statItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textHintColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
