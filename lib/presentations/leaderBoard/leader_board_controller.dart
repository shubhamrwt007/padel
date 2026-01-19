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
  final isLoadingMore = false.obs;
  
  // Pagination
  int currentPage = 1;
  final hasMoreData = true.obs;
  
  // API data
  final apiLeaderboardData = <Map<String, dynamic>>[].obs;
  final apiTopThree = <Player>[].obs;
  final myRankData = Rxn<Map<String, dynamic>>();


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

  // ✅ Use only API data for leaderboard
  List<Map<String, dynamic>> get leaderboardData {
    return apiLeaderboardData;
  }

  // Get top 3 players for podium
  List<Player> get topThreePlayers {
    return apiTopThree;
  }

  // Fetch leaderboard data from API
  Future<void> fetchLeaderboardData({bool isRefresh = false}) async {
    try {
      if (isRefresh) {
        isLoading.value = true;
        currentPage = 1;
        apiLeaderboardData.clear();
      } else {
        isLoading.value = true;
      }
      
      final userId = storage.read("userId");
      print('🔍 Fetching leaderboard for userId: $userId, page: $currentPage');
      
      final response = await _repository.getLeaderBoard(id: userId, page: currentPage, limit: 10);
      print('🔍 API Response success: ${response.success}');
      
      if (response.success == true && response.data != null) {
        print('🔍 Converting API data to format');
        _convertApiDataToFormat(response.data!, isRefresh: isRefresh);
        print('🔍 After conversion - apiLeaderboardData length: ${apiLeaderboardData.length}');
      } else {
        print('🔍 API response failed or no data');
      }
    } catch (e) {
      print('❌ Error fetching leaderboard: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Load more data for pagination
  Future<void> loadMoreData() async {
    if (isLoadingMore.value || !hasMoreData.value) return;
    
    try {
      isLoadingMore.value = true;
      currentPage++;
      
      final userId = storage.read("userId");
      final response = await _repository.getLeaderBoard(id: userId, page: currentPage, limit: 10);
      
      if (response.success == true && response.data != null) {
        _convertApiDataToFormat(response.data!, isLoadMore: true);
      }
    } catch (e) {
      print('❌ Error loading more data: $e');
      currentPage--; // Revert page increment on error
    } finally {
      isLoadingMore.value = false;
    }
  }

  void _convertApiDataToFormat(LeaderboardData data, {bool isRefresh = false, bool isLoadMore = false}) {
    print('🔍 Converting data - leaderboard: ${data.leaderboard?.length}');
    
    // Convert top three and myRank only on initial load or refresh
    if (!isLoadMore) {
      if (data.topThree != null && data.topThree!.isNotEmpty) {
        apiTopThree.value = data.topThree!.map((item) => Player(
          item.name ?? '',
          item.xpPoints ?? 0,
          item.profilePic ?? '',
        )).toList();
        print('🔍 Top three converted: ${apiTopThree.length} items');
      }

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
        print('🔍 MyRank converted: ${myRankData.value}');
      }
    }

    // Convert leaderboard data
    if (data.leaderboard != null && data.leaderboard!.isNotEmpty) {
      final newData = data.leaderboard!.map((item) {
        return {
          'rank': item.rank ?? 0,
          'name': item.name ?? '',
          'score': item.xpPoints ?? 0,
          'change': 0,
          'image': item.profilePic ?? '',
          'streak': item.currentWinStreak ?? 0,
          'matches': item.matches ?? 0,
          'wins': item.wins ?? 0,
          'losses': item.losses ?? 0,
        };
      }).toList();
      
      if (isLoadMore) {
        apiLeaderboardData.addAll(newData);
      } else {
        apiLeaderboardData.value = newData;
      }
      
      // Check if there's more data
      hasMoreData.value = data.leaderboard!.length >= 10;
      print('🔍 Leaderboard converted: ${apiLeaderboardData.length} total items, hasMore: ${hasMoreData.value}');
    } else {
      hasMoreData.value = false;
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