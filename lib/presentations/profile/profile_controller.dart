// ✅ FILE: profile_controller.dart
 import 'dart:developer';
import 'package:padel_mobile/core/network/dio_client.dart';
import 'package:padel_mobile/data/request_models/logout_model.dart';
import 'package:padel_mobile/data/response_models/home_models/profile_model.dart';
import 'package:padel_mobile/presentations/booking/details_page/details_page_controller.dart';
import 'package:padel_mobile/presentations/profile/widgets/profile_exports.dart';
import 'package:padel_mobile/presentations/chat/chat_controller.dart';
import 'package:padel_mobile/repositories/authentication_repository/login_repository.dart';
import 'package:padel_mobile/repositories/home_repository/home_repository.dart';

class ProfileController extends GetxController {
  // Repositories
  ProfileRepository profileRepository = ProfileRepository();
  var selectedIndex = (-1).obs;
  // Text Controllers
  RxBool isLoading = false.obs;
 
  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await fetchUserProfile();
      await fetCustomerLeaderBoardRank();
    });
  }
var profileModel = Rxn<ProfileModel>();
  Future<void> fetchUserProfile() async {
    try {
      isLoading.value = true;
      ProfileModel result = await profileRepository.fetchUserProfile();
      if (result.status == "200") {
        profileModel.value = result;
        storage.write('existsOpenMatchData', result.existsOpenMatchData);
        log("PROFILE MODEL => ${profileModel.value}");
        update();
      } else {
        CustomLogger.logMessage(msg: result.message ?? 'Failed to fetch profile', level: LogLevel.error);
      }
    } catch (e, st) {
      CustomLogger.logMessage(msg: e.toString(), level: LogLevel.error, st: st);
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        isLoading.value = false;
      });
    }
  }

  void showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppStrings.areYouSureToLogout, textAlign: TextAlign.center),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () async {
                    onLogOut();
                  },
                  child: Container(
                    height: Get.height * 0.04,
                    width: Get.width * 0.22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.textColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      AppStrings.yes,
                      style: TextStyle(color: AppColors.whiteColor),
                    ),
                  ).paddingOnly(right: 10),
                ),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    height: Get.height * 0.04,
                    width: Get.width * 0.22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      AppStrings.no,
                      style: TextStyle(color: AppColors.whiteColor),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  void showDeleteAccountDialog(BuildContext context) {
    Get.defaultDialog(
      title: "Delete Account",
      titleStyle: Get.textTheme.headlineLarge,
      middleTextStyle: Get.textTheme.bodySmall,
      middleText: "This will permanently delete your account and all associated data, including personal information, content, and preferences. You won’t be able to recover anything after this action.",
      textConfirm: "Delete",
      confirmTextColor: Colors.white,
      textCancel: "Cancel",
      buttonColor: Colors.red,
      onConfirm: () {
        // Call delete account API here
        deleteCustomer();
      },
      onCancel: () {
        Get.back();
      },
    );
  }
  Future<void>deleteCustomer()async{
    try{
      final response = await profileRepository.deleteCustomer();
      if(response.status == 200){
        CustomLogger.logMessage(msg: response.message??"User Delete", level: LogLevel.error);

        Get.offAllNamed(RoutesName.login);
      }
    }catch(e){
      CustomLogger.logMessage(msg: "Error-> $e", level: LogLevel.error);
    }
  }

  ///Logout Api-----------------------------------------------------------------
  LoginRepository loginRepository = Get.put(LoginRepository());
  Future<void> onLogOut() async {
    FocusManager.instance.primaryFocus!.unfocus();
    try {
      if (isLoading.value) return;
      Get.dialog(
        Center(
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                child: LoadingWidget(color: AppColors.whiteColor,)
            ),
          ),
        ),
        barrierDismissible: false,
      );
      final firebaseToken = storage.read('firebase_token');
      isLoading.value = true;

      // Build request body conditionally excluding fcmToken if null or empty
      final Map<String, dynamic> body = {
        "tokens":firebaseToken??""
      };

      // if (firebaseToken != null && firebaseToken.toString().isNotEmpty) {
      //   body["fcmToken"] = firebaseToken;
      // }

      LogOutModel result = await loginRepository.logOutUser(body: body);

      if (result.status == 200) {
        log("🚪 LOGOUT: Starting logout process");

        // Complete cleanup of all socket connections and controllers
        try {
          // Disconnect shared socket first
          log("🔌 LOGOUT: Disconnecting shared socket");
          ChatController.disconnectSharedSocket();
          log("✅ LOGOUT: Shared socket disconnected");

          // Clear static message cache
          log("🧹 LOGOUT: Clearing ChatController static message cache");
          ChatController.clearMessageCache();
          log("✅ LOGOUT: Message cache cleared");

          // Disconnect details controller socket if exists
          if (Get.isRegistered<DetailsController>()) {
            log("🔍 LOGOUT: DetailsController found, disconnecting socket");
            // final detailsCtrl = Get.find<DetailsController>();
            // detailsCtrl.disconnectSocket();
            log("✅ LOGOUT: Details socket disconnected");
          }

          // Delete all controller instances to force fresh creation
          if (Get.isRegistered<ChatController>()) {
            log("🗑️ LOGOUT: Deleting ChatController instance");
            Get.delete<ChatController>(force: true);
            log("✅ LOGOUT: ChatController deleted");
          }

          if (Get.isRegistered<DetailsController>()) {
            log("🗑️ LOGOUT: Deleting DetailsController instance");
            Get.delete<DetailsController>(force: true);
            log("✅ LOGOUT: DetailsController deleted");
          }

        } catch (e) {
          log("❌ LOGOUT: Error during cleanup: $e");
        }

        // Clear storage completely
        log("🔍 LOGOUT: BEFORE ERASE: ${storage.getKeys().map((k) => "$k: ${storage.read(k)}").join(", ")}");
        await storage.erase(); // clear all stored data
        log("🧹 LOGOUT: AFTER ERASE: Storage cleared");

        // Small delay to ensure cleanup is complete
        await Future.delayed(const Duration(milliseconds: 500));
        log("🏁 LOGOUT: Navigating to login screen");

        Get.offAllNamed(RoutesName.login);
      } else {
        CustomLogger.logMessage(msg: result.message!, level: LogLevel.error);

      }
    } catch (e) {
      log(e.toString());
    } finally {
      isLoading.value = false;
      Get.back(); // Close the dialog
    }
  }

  ///Pending Request Count------------------------------------------------------
  var pendingRequestCount = 0.obs;
  final HomeRepository homeRepository = Get.put(HomeRepository());
  Future<void> fetCustomerLeaderBoardRank() async {
    try {
      final response = await homeRepository.getPendingRequestCount();
      pendingRequestCount.value = response.count??0;
      print(response);
    } catch (e) {
      print('Error fetching Customer Rank: $e');
    }
  }
}
