import 'package:get/get.dart';
import 'package:padel_mobile/presentations/league/live_and_complete_league_match_details/live_and_complete_league_match_controller.dart';

class LiveAndCompleteLeagueMatchBinding implements Bindings{
  @override
  void dependencies() {
    Get.put(LiveAndCompleteLeagueMatchController());
  }

}