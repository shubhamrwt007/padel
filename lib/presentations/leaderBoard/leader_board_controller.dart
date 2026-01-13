import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:padel_mobile/core/network/dio_client.dart';
import 'package:padel_mobile/repositories/leaderBoard_repo/leaderBoard_repository.dart';
import 'package:padel_mobile/data/response_models/leaderBoard/get_leaderBoard_model.dart';

class Player {
  final String name;
  final int points;
  final String imageUrl;
  final String record;

  Player(this.name, this.points, this.imageUrl, {this.record = "8 - 7 - 0"});
}

class LeaderboardController extends GetxController {
  final LeaderboardRepository _repository = LeaderboardRepository();
  
  // Loading state
  final isLoading = false.obs;
  
  // API data
  final apiLeaderboardData = <Map<String, dynamic>>[].obs;
  final apiTopThree = <Player>[].obs;
  final myRankData = Rxn<Map<String, dynamic>>();
  // Player list
  final players = <Player>[
    Player("Dianne Smith", 122, ""),
    Player("Jane Cooper", 110, ""),
    Player("Lily Johnson", 100, ""),
    Player("Sophia Brown", 95, ""),
    Player("Olivia Davis", 90, ""),
    Player("Emma Wilson", 88, ""),
    Player("Ava Martinez", 85, ""),
    Player("Isabella Anderson", 83, ""),
    Player("Mia Thomas", 80, ""),
    Player("Charlotte Taylor", 78, ""),
    Player("Amelia Moore", 75, ""),
  ].obs;
  final clubs = <Player>[
    Player("Raptors Club", 200, ""),
    Player("Falcons Club", 180, ""),
    Player("Lions Club", 175, ""),
    Player("Eagles Club", 160, ""),
    Player("Wolves Club", 150, ""),
  ].obs;

  final selectedTab = 0.obs;
  final leftScore = 16.obs;
  final rightScore = 22.obs;

  final categories = ['Player'];
  var selectedCategory = 'Player'.obs;
  RxDouble borderRadius = 24.0.obs;

  var expandedIndex = (-1).obs;
  var myRankExpanded = false.obs;
  RxBool isHandleVisible = true.obs;
  var selectedGender = ''.obs;
  var selectedYear = ''.obs;
  var showStateFilters = false.obs;
  var selectedCity = 'All Location'.obs;

  final List<String> indianCities = [
    'All Location',
    'Mumbai',
    'Delhi',
    'Bengaluru',
    'Chennai',
    'Hyderabad',
    'Pune',
    'Kolkata',
    'Jaipur',
    'Ahmedabad',
    'Lucknow',
    'Indore',
    'Chandigarh',
    'Bhopal',
    'Surat',
    'Patna',
    'Nagpur',
    'Coimbatore',
    'Goa',
    'Thiruvananthapuram',
  ];

  // ✅ Convert players into leaderboardData (Map format)
  List<Map<String, dynamic>> get leaderboardData {
    // Use API data for Player tab, static data for others
    if (selectedCategory.value == 'Player' && apiLeaderboardData.isNotEmpty) {
      return apiLeaderboardData;
    }
    
    final list = selectedCategory.value == 'Team' ? clubs : players;

    return List.generate(list.length, (index) {
      final p = list[index];
      return {
        'rank': index + 1,
        'name': p.name,
        'score': p.points,
        'change': (index % 3 == 0)
            ? 1
            : (index % 3 == 1 ? -1 : 0), // mock rank change
        'image': p.imageUrl,
        'streak': (index + 1) * 2,
        'matches': 40 + index,
        'wins': 20 + index,
        'losses': 10 + index,
      };
    });
  }

  // Get top 3 players for podium
  List<Player> get topThreePlayers {
    if (selectedCategory.value == 'Player' && apiTopThree.isNotEmpty) {
      return apiTopThree;
    }
    
    final list = selectedCategory.value == 'Team' ? clubs : players;
    return list.take(3).toList();
  }

  // Fetch leaderboard data from API
  Future<void> fetchLeaderboardData() async {
    try {
      isLoading.value = true;
       final userId = storage.read("userId");
      final response = await _repository.getLeaderBoard(id: userId);
      
      if (response.success == true && response.data != null) {
        // Convert API data to required format
        _convertApiDataToFormat(response.data!);
      }
    } catch (e) {
      print('Error fetching leaderboard: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _convertApiDataToFormat(LeaderboardData data) {
    // Convert top three
    if (data.topThree != null) {
      apiTopThree.value = data.topThree!.map((item) => Player(
        item.name ?? '',
        item.xpPoints ?? 0,
        item.profilePic ?? '',
      )).toList();
    }

    // Convert myRank
    if (data.myRank != null) {
      myRankData.value = {
        'rank': data.myRank!.rank ?? 0,
        'name': data.myRank!.name ?? '',
        'score': data.myRank!.xpPoints ?? 0,
        'change': 0,
        'image': data.myRank!.profilePic ?? '',
        'streak': data.myRank!.currentWinStreak ?? 0,
        'matches': data.myRank!.matches ?? 0,
        'wins': data.myRank!.wins ?? 0,
        'losses': data.myRank!.losses ?? 0,
      };
    }

    // Convert leaderboard
    if (data.leaderboard != null) {
      apiLeaderboardData.value = data.leaderboard!.map((item) {
        return {
          'rank': item.rank ?? 0,
          'name': item.name ?? '',
          'score': item.xpPoints ?? 0,
          'change': 0, // API doesn't provide change data
          'image': item.profilePic ?? '',
          'streak': item.currentWinStreak ?? 0,
          'matches': item.matches ?? 0,
          'wins': item.wins ?? 0,
          'losses': item.losses ?? 0,
        };
      }).toList();
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchLeaderboardData();
  }

  void toggleExpand(int index) {
    expandedIndex.value = expandedIndex.value == index ? -1 : index;
  }
  
  void toggleMyRankExpand() {
    myRankExpanded.value = !myRankExpanded.value;
  }
}