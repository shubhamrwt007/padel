// import 'dart:io';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:get_storage/get_storage.dart';
// import 'package:padel_mobile/configs/components/app_toast.dart';
// import 'package:package_info_plus/package_info_plus.dart';
//
// import '../../configs/components/snack_bars.dart';
// import '../../handler/logger.dart';
// import '../../repositories/app_version_repository/app_version_repository.dart';
// import '../../services/network/connectivity_service.dart';
// import '../auth/login/widgets/login_exports.dart';
// import 'widgets/force_update_dialog.dart';
//
// class SplashController extends GetxController {
//   // final ConnectivityService _connectivityService = ConnectivityService();
//   // final AppVersionRepository _appVersionRepository = AppVersionRepository();
//
//   @override
//   void onInit() {
//     super.onInit();
//     // checkAppVersionAndNavigate();
//     checkTokenAndNavigate();
//   }
//
//   // Future<void> checkAppVersionAndNavigate() async {
//   //   await Future.delayed(const Duration(seconds: 3));
//   //
//   //   final hasInternet = await _connectivityService.checkConnectivity();
//   //   if (!hasInternet) {
//   //     AppToast.error("You're offline. Some features may not work properly.");
//   //     checkTokenAndNavigate();
//   //     return;
//   //   }
//   //
//   //   try {
//   //     final packageInfo = await PackageInfo.fromPlatform();
//   //     final currentVersion = packageInfo.version;
//   //     final platform = Platform.isAndroid ? 'android' : 'ios';
//   //
//   //     final response = await _appVersionRepository.checkAppVersion(
//   //       body: {
//   //         'platform': platform,
//   //         'currentVersion': currentVersion,
//   //       },
//   //     );
//   //
//   //     if (response.forceUpdate == true) {
//   //       Get.dialog(
//   //         ForceUpdateDialog(latestVersion: response.data?.latestVersion ?? ''),
//   //         barrierDismissible: false,
//   //       );
//   //     } else {
//   //       checkTokenAndNavigate();
//   //     }
//   //   } catch (e) {
//   //     CustomLogger.logMessage(msg: "Version check error: $e", level: LogLevel.error);
//   //     checkTokenAndNavigate();
//   //   }
//   // }
//
//   void checkTokenAndNavigate() {
//     final storage = GetStorage();
//     String? isToken = storage.read("token");
//
//     CustomLogger.logMessage(msg: "TOKEN ---> $isToken", level: LogLevel.info);
//
//     if (isToken != null && isToken.isNotEmpty) {
//       Get.offAllNamed(RoutesName.bottomNav);
//     } else {
//       Get.offAllNamed(RoutesName.login);
//     }
//   }
// }
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_storage/get_storage.dart';
import 'package:padel_mobile/configs/components/app_toast.dart';
import '../../configs/components/snack_bars.dart';
import '../../handler/logger.dart';
import '../../services/network/connectivity_service.dart';
import '../auth/login/widgets/login_exports.dart';

class SplashController extends GetxController {
  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  void onInit() {
    super.onInit();
    checkTokenAndNavigate();
  }

  void checkTokenAndNavigate() async {
    await Future.delayed(const Duration(seconds: 3));

    final storage = GetStorage();
    String? isToken = storage.read("token");

    CustomLogger.logMessage(msg: "TOKEN ---> $isToken", level: LogLevel.info);

    final hasInternet = await _connectivityService.checkConnectivity();

    if (isToken != null && isToken.isNotEmpty) {
      if (!hasInternet) {
        AppToast.error("You're offline. Some features may not work properly.");
      }
      Get.offAllNamed(RoutesName.bottomNav);
    } else {
      Get.offAllNamed(RoutesName.login);
    }
  }
}