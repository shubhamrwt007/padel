import 'package:get/get.dart';
import 'package:padel_mobile/presentations/ipt_tournament/ipt_tournament_match_lists/ipt_tournament_match_list_controller.dart';
import 'package:padel_mobile/presentations/league/league_match_lists/league_match_list_controller.dart';

class IptTournamentListBinding implements Bindings{
  @override
  void dependencies() {
    Get.put(IptTournamentListController());
  }

}