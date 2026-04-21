import 'package:get/get.dart';
import 'package:padel_mobile/presentations/ipt_tournament/ipt_tournament_controller.dart';
import 'package:padel_mobile/presentations/leaderBoard/leader_board_controller.dart';

class IptTournamentBinding implements Bindings{
  @override
  void dependencies() {
    Get.put(IptTournamentController());
  }
}