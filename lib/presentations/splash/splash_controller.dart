import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_storage/get_storage.dart';
import 'package:padel_mobile/configs/components/app_toast.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../configs/components/snack_bars.dart';
import '../../handler/logger.dart';
import '../../repositories/app_version_repository/app_version_repository.dart';
import '../../services/network/connectivity_service.dart';
import '../auth/login/widgets/login_exports.dart';
import 'widgets/force_update_dialog.dart';

class SplashController extends GetxController {
  final ConnectivityService _connectivityService = ConnectivityService();
  final AppVersionRepository _appVersionRepository = AppVersionRepository();

  @override
  void onInit() {
    super.onInit();
    checkAppVersionAndNavigate();
  }

  Future<void> checkAppVersionAndNavigate() async {
    await Future.delayed(const Duration(seconds: 3));

    final hasInternet = await _connectivityService.checkConnectivity();
    if (!hasInternet) {
      AppToast.error("You're offline. Some features may not work properly.");
      checkTokenAndNavigate();
      return;
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final platform = Platform.isAndroid ? 'android' : 'ios';

      final response = await _appVersionRepository.checkAppVersion(
        body: {
          'platform': platform,
          'currentVersion': currentVersion,
        },
      );

      if (response.forceUpdate == true) {
        _showForceUpdateDialog(response.data?.latestVersion ?? '');
      } else if (response.updateRequired == true) {
        _showOptionalUpdateDialog(response.data?.latestVersion ?? '');
      } else {
        checkTokenAndNavigate();
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "Version check error: $e", level: LogLevel.error);
      checkTokenAndNavigate();
    }
  }

  void _showForceUpdateDialog(String latestVersion) {
    Get.dialog(
      ForceUpdateDialog(latestVersion: latestVersion),
      barrierDismissible: false,
    );
  }

  void _showOptionalUpdateDialog(String latestVersion) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Update Available', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('A new version ($latestVersion) is available. Would you like to update now?'),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              checkTokenAndNavigate();
            },
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _openStore();
            },
            child: const Text('Update'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  void _openStore() async {
    final url = Platform.isAndroid
        ? Uri.parse('https://play.google.com/store/search?q=swoot&c=apps')
        : Uri.parse('https://apps.apple.com/app/id6747494631');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "Error opening store: $e", level: LogLevel.error);
    }
  }

  void checkTokenAndNavigate() {
    final storage = GetStorage();
    String? isToken = storage.read("token");

    CustomLogger.logMessage(msg: "TOKEN ---> $isToken", level: LogLevel.info);

    if (isToken != null && isToken.isNotEmpty) {
      Get.offAllNamed(RoutesName.bottomNav);
    } else {
      Get.offAllNamed(RoutesName.login);
    }
  }
}