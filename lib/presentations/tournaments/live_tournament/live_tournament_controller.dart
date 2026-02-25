import 'package:get/get.dart';

class LiveTournamentController extends GetxController{
  RxInt teamAScore = 2.obs;
  RxInt teamBScore = 0.obs;
  final RxInt selectedTab = 0.obs;

  RxInt set3TeamAScore = 6.obs;
  RxInt set3TeamBScore = 4.obs;

  RxString setStatus = "Ongoing".obs;

  List<int> teamARounds = [30, 30, 30, 30];
  List<int> teamBRounds = [45, 45, 45, 45];
}