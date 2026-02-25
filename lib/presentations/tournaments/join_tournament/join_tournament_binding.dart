import 'package:get/get.dart';
import 'package:padel_mobile/presentations/tournaments/join_tournament/join_tournament_controller.dart';

class JoinTournamentBinding implements Bindings{
  @override
  void dependencies() {
    Get.put(JoinTournamentController());
  }
}