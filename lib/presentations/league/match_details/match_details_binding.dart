import 'package:get/get.dart';
import 'package:padel_owner/presentations/tournament/match_details/match_details_controller.dart';

class MatchDetailsBinding implements Bindings{
  @override
  void dependencies() {
    Get.put(MatchDetailsController());
  }
}