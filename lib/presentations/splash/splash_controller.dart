import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_storage/get_storage.dart';

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
        Fluttertoast.showToast(
          msg: "You're offline. Some features may not work properly.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
          timeInSecForIosWeb: 3,
        );
      }
      Get.offAllNamed(RoutesName.bottomNav);
    } else {
      Get.offAllNamed(RoutesName.login);
    }
  }
}
