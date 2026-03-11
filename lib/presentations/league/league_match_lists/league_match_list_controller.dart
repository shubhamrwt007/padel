import 'package:padel_mobile/presentations/auth/forgot_password/widgets/forgot_password_exports.dart';

class LeagueMatchListController extends GetxController{
  final matchTab = 0.obs;
@override
  void onInit() {
    matchTab.value = Get.arguments['matchTab'];
    super.onInit();
  }
}