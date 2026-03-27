import 'package:get/get.dart';
import 'package:padel_mobile/presentations/leaderBoard/leader_board_controller.dart';

class LeagueBinding implements Bindings{
  @override
  void dependencies() {
    Get.put(LeaderboardController());
  }
}