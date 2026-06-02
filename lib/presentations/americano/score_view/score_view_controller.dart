import 'package:padel_mobile/presentations/americano/widgets/americano_exports.dart';
import 'package:padel_mobile/repositories/americano_repository/americano_repository.dart';
import 'package:padel_mobile/data/response_models/americano_models/get_americano_model.dart';
import 'package:padel_mobile/handler/logger.dart';

class Player {
  final String name;
  final int points;
  final String imageUrl;
  final String record;

  Player(this.name, this.points, this.imageUrl, {this.record = "8 - 7 - 0"});
}

class ScoreViewController extends GetxController {
  final AmericanoRepository _repository = AmericanoRepository();

  RxString americanoMatchId = "".obs;
  RxList<AmericanoPlayer> leaderboardPlayers = <AmericanoPlayer>[].obs;
  Rxn<MyRankInfo> myRankInfo = Rxn<MyRankInfo>();
  RxBool isLoading = false.obs;

  // Sample data (fallback in case API returns empty, or for fallback compatibility)
  final players = <Player>[
    Player("Dianne", 122, "https://i.pravatar.cc/150?img=1"),
    Player("Jane", 110, "https://i.pravatar.cc/150?img=2"),
    Player("Lily", 100, "https://i.pravatar.cc/150?img=3"),
    Player("Sophia", 95, "https://i.pravatar.cc/150?img=4"),
    Player("Olivia", 90, "https://i.pravatar.cc/150?img=5"),
    Player("Emma", 88, "https://i.pravatar.cc/150?img=6"),
    Player("Ava", 85, "https://i.pravatar.cc/150?img=7"),
    Player("Isabella", 83, "https://i.pravatar.cc/150?img=8"),
    Player("Mia", 80, "https://i.pravatar.cc/150?img=9"),
    Player("Charlotte", 78, "https://i.pravatar.cc/150?img=10"),
    Player("Amelia", 75, "https://i.pravatar.cc/150?img=11"),
  ].obs;

  final selectedTab = 0.obs;
  final leftScore = 16.obs;
  final rightScore = 22.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null && args is Map) {
      americanoMatchId.value = args['americanoMatchId'] ?? '';
    } else if (args != null && args is String) {
      americanoMatchId.value = args;
    }
    fetchLeaderboard();
  }

  Future<void> fetchLeaderboard() async {
    if (americanoMatchId.value.isEmpty) return;
    isLoading.value = true;
    try {
      final response = await _repository.getAmericanoLeaderboard(americanoMatchId.value);
      final playersList = response.players;

      // Sort players by totalPoints descending, then pointDifference descending
      playersList.sort((a, b) {
        int cmp = (b.totalPoints ?? 0).compareTo(a.totalPoints ?? 0);
        if (cmp != 0) return cmp;
        return (b.pointDifference ?? 0).compareTo(a.pointDifference ?? 0);
      });

      leaderboardPlayers.assignAll(playersList);
      myRankInfo.value = response.myRankInfo;
    } catch (e) {
      CustomLogger.logMessage(
        msg: "Error fetching Americano leaderboard in controller: $e",
        level: LogLevel.error,
      );
    } finally {
      isLoading.value = false;
    }
  }
}