import 'package:padel_mobile/presentations/americano/widgets/americano_exports.dart';
class Player {
  final String name;
  final int points;
  final String imageUrl;
  final String record;

  Player(this.name, this.points, this.imageUrl, {this.record = "8 - 7 - 0"});
}

class ScoreViewController extends GetxController {
  // Sample data
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
}