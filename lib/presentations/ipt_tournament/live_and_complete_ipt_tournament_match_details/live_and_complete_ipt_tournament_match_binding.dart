import 'package:get/get.dart';

import 'live_and_complete_ipt_tournament_match_controller.dart';

class LiveAndCompleteIptTournamentMatchBinding implements Bindings{
  @override
  void dependencies() {
    Get.put(LiveAndCompleteIptTournamentMatchController());
  }

}