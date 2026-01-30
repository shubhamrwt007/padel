import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_cropper/image_cropper.dart';
import 'package:padel_mobile/presentations/profile/widgets/profile_exports.dart';
class EditProfileController extends GetxController{
  ProfileController profileController = Get.put(ProfileController());
    TextEditingController nameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  // Rx<TextEditingController> dobController = TextEditingController().obs;
  // TextEditingController locationController = TextEditingController();
 var selectedDate = "".obs;
  ProfileRepository profileRepository = ProfileRepository();

  RxBool isLoading = false.obs;
  RxString selectedGender = ''.obs;
  Rx<XFile?> profileImage = Rx<XFile?>(null);
  RxBool isProfileUpdated = false.obs;
    RxString profileImageUrl = ''.obs;
  void setValues() {
    final model = profileController.profileModel.value;
    nameController.text = model?.response?.name ?? '';
    lastNameController.text = model?.response?.lastName ??'';
    emailController.text = model?.response?.email ?? '';
    phoneController.text = model?.response?.phoneNumber?.toString() ?? '';
    selectedGender.value = model?.response?.gender ?? "";
    profileImageUrl.value = model?.response?.profilePic?.toString() ?? '';
    // Format DOB
    final dob = model?.response?.dob;
    if (dob != null && dob.isNotEmpty) {
      try {
        DateTime parsedDate = DateTime.parse(dob);
        selectedDate.value = DateFormat('dd-MM-yyyy').format(parsedDate);
      } catch (e) {
        selectedDate.value = dob;
      }
    } else {
      selectedDate.value = "";
    }
    selectedLocation.value = model?.response?.city ?? '';
  }

  void selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      selectedDate.value = DateFormat('dd-MM-yyyy').format(pickedDate); // use dash
    }
  }
  Future<void> showImageSourceActionSheet(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: EdgeInsets.only(top: 12, bottom: 8),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Select Image Source',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ),

                // Divider
                Divider(height: 1, thickness: 1, color: Colors.grey[200]),
                // Options
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildOptionTile(
                        context: context,
                        icon: Icons.camera_alt,
                        iconColor: Colors.blue,
                        title: 'Take a photo',
                        subtitle: 'Use camera to capture',
                        onTap: () async {
                          Get.back();
                          await pickImage(ImageSource.camera);
                        },
                      ),

                      SizedBox(height: 8),

                      _buildOptionTile(
                        context: context,
                        icon: Icons.photo_library,
                        iconColor: Colors.green,
                        title: 'Choose from gallery',
                        subtitle: 'Select from your photos',
                        onTap: () async {
                          Get.back();
                          await pickImage(ImageSource.gallery);
                        },
                      ),

                      SizedBox(height: 16),

                      // Cancel button
 
                      SizedBox(

                         width: double.infinity,

                        child: OutlinedButton(
                          onPressed: () => Get.back(),

                          style: OutlinedButton.styleFrom(

                            padding: EdgeInsets.symmetric(vertical: 16),

                            side: BorderSide(color: Colors.grey[300]!),

                            shape: RoundedRectangleBorder(

                              borderRadius: BorderRadius.circular(12),

                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom padding
                SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> updateProfile() async {
    if (isLoading.value) return;
    FocusManager.instance.primaryFocus!.unfocus();
    try {
      isLoading.value = true;

      Map<String, dynamic> locationJson = {
        "type": "Point",
        "coordinates": [77.5947, 12.9717],
      };

      String formattedDate;
      if (selectedDate.value.isNotEmpty) {
        DateTime dateTime = parseDateFromString(selectedDate.value);
        formattedDate = DateFormat('yyyy-MM-dd').format(dateTime);
      } else {
        formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      }

      final updatedProfile = await profileRepository.updateUserProfile(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        // lastName: lastNameController.text.trim(),
        gender: selectedGender.value,
        dob: formattedDate,
        city: selectedLocation.value,
        location: locationJson,
        profileImage: profileImage.value != null ? File(profileImage.value!.path) : null,
      );

      if (updatedProfile.status == "200") {
        await profileController.fetchUserProfile();
        Get.back();
        SnackBarUtils.showSuccessSnackBar(updatedProfile.message??"");
      } else {
        CustomLogger.logMessage(msg: "UPDATE PROFILE ERROR",level: LogLevel.error);
      }
    } catch (e) {
      CustomLogger.logMessage(msg: 'Error updating profile: $e',level: LogLevel.error);
    } finally {
      isLoading.value = false;
    }
  }

  DateTime parseDateFromString(String dateStr) {
    try {
      return DateFormat('dd-MM-yyyy').parse(dateStr); // same format
    } catch (_) {
      return DateTime.now();
    }
  }


  Future<void> pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      await _cropImage(image.path);
    }
  }

  Future<void> _cropImage(String imagePath) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 100,
        maxWidth: 1000,
        maxHeight: 1000,
        compressFormat: ImageCompressFormat.jpg,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: AppColors.primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (croppedFile != null) {
        profileImage.value = XFile(croppedFile.path);
        CustomLogger.logMessage(msg: 'Image cropped: ${croppedFile.path}', level: LogLevel.info);
      } else {
        CustomLogger.logMessage(msg: 'Crop cancelled', level: LogLevel.info);
      }
    } catch (e) {
      CustomLogger.logMessage(msg: 'Crop error: $e', level: LogLevel.error);
      profileImage.value = XFile(imagePath);
    }
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  ///Get Location Api-------------------------------------------------------
  var locations = <GetLocationData>[].obs;
  var isLocationLoading = false.obs;
  var selectedLocation = "".obs;
  SignUpRepository signUpRepository = Get.put(SignUpRepository());
  Future<void>fetchLocations()async{
    isLocationLoading.value = true;
    try{
      final response = await signUpRepository.getLocations();
      if(response.status == true){
        locations.assignAll(response.data?.toList()??[]);
      }

    }catch(e){
      CustomLogger.logMessage(msg: "Error :-> $e", level: LogLevel.error);
    }finally{
      isLocationLoading.value = false;
    }
  }
  Future<void> refreshProfile() async {
    await profileController.fetchUserProfile();
    setValues();
    await fetchLocations();
  }

  @override
  void onInit()async {
    await profileController.fetchUserProfile();
    setValues();
   await fetchLocations();
    super.onInit();
  }
}