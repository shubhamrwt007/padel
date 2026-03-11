import 'package:get/get.dart';

class LiveAndCompleteLeagueMatchController extends GetxController{
  RxInt teamAScore = 2.obs;
  RxInt teamBScore = 0.obs;
  final RxInt selectedTab = 0.obs;
  var matchType = "".obs;
  RxList<bool> isSet2Expanded = <bool>[false, false, false, false].obs;

  @override
  void onInit() {
   matchType.value= Get.arguments["matchType"];
    super.onInit();
  }
}