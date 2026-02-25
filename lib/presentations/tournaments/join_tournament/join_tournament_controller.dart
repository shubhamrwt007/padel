import 'package:get/get.dart';

class JoinTournamentController extends GetxController{
  RxInt totalSlots = 20.obs;
  RxInt slotsLeft = 20.obs;

  RxList<Map<String, dynamic>> teams = [
    {
      "team": "Team A",
      "players": [
        "Eleanor Pena",
        "Kristin Watson",
      ]
    },
    {
      "team": "Team B",
      "players": [
        "Eleanor Pena",
        "Kristin Watson",
      ]
    },
  ].obs;
}