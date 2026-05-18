import 'package:get/get.dart';
import 'package:padel_mobile/presentations/tournaments/live_tournament/live_tournament_controller.dart';

class LiveTournamentBinding implements Bindings{
  @override
  void dependencies() {
    Get.put(LiveTournamentController());
  }

}