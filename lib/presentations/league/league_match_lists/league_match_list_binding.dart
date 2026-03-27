import 'package:get/get.dart';
import 'package:padel_mobile/presentations/league/league_match_lists/league_match_list_controller.dart';

class LeagueMatchListBinding implements Bindings{
  @override
  void dependencies() {
    Get.put(LeagueMatchListController());
  }

}