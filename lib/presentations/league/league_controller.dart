import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/repositories/league_repository/league_repository.dart';
import 'package:padel_mobile/data/response_models/league/get_all_schedule_live_matches_model.dart';
import 'package:padel_mobile/data/response_models/league/get_league_sponsors_model.dart';
import 'package:padel_mobile/data/response_models/league/get_league_leader_board_model.dart';

class LeagueController extends GetxController with GetSingleTickerProviderStateMixin {
  final RxInt selectedTab = 0.obs;

  void setSelectedTab(int index) {
    selectedTab.value = index;
    if (index == 0) {
      matchTab.value = 1;
      tabController.animateTo(1);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (pageController.hasClients) pageController.jumpToPage(1);
      });
    }
  }
  final RxInt matchTab = 1.obs; // 0: Upcoming, 1: Live, 2: Results
  late PageController pageController;
  late TabController tabController;
  
  final LeagueRepository _leagueRepository = LeagueRepository();
  final Rx<GetAllScheduleLiveMatchesModel?> liveMatches = Rx<GetAllScheduleLiveMatchesModel?>(null);
  final RxBool isLoadingLiveMatches = false.obs;
  final Rx<GetAllScheduleLiveMatchesModel?> upcomingMatches = Rx<GetAllScheduleLiveMatchesModel?>(null);
  final RxBool isLoadingUpcomingMatches = false.obs;
  final Rx<GetAllScheduleLiveMatchesModel?> resultMatches = Rx<GetAllScheduleLiveMatchesModel?>(null);
  final RxBool isLoadingResultMatches = false.obs;
  final Rx<GetLeagueSponsorsModel?> sponsors = Rx<GetLeagueSponsorsModel?>(null);
  final RxBool isLoadingSponsors = false.obs;
  final Rx<GetLeagueLeaderBoardModel?> leaderBoard = Rx<GetLeagueLeaderBoardModel?>(null);
  final RxBool isLoadingLeaderBoard = false.obs;
  
  String? leagueId;

  @override
  void onInit() {
    super.onInit();
    // Get leagueId from arguments
    leagueId = Get.arguments?['leagueId'];
    print('🎯 League Controller - Received leagueId: $leagueId');
    
    pageController = PageController(initialPage: 1);
    tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    fetchLiveMatches();
    fetchUpcomingMatches();
    fetchResultMatches();
    fetchSponsors();
    fetchLeaderBoard();
  }

  @override
  void onClose() {
    pageController.dispose();
    tabController.dispose();
    super.onClose();
  }

  void onTabChanged(int index) {
    matchTab.value = index;
    final currentPage = (pageController.hasClients ? pageController.page : null)?.round() ?? pageController.initialPage;
    final distance = (currentPage - index).abs();

    // When moving 0 -> 2 (or 2 -> 0), `animateToPage` scrolls through page 1,
    // which briefly shows the "Live" page. Jump for non-adjacent transitions.
    if (distance > 1) {
      pageController.jumpToPage(index);
    } else {
      pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void onPageChanged(int index) {
    matchTab.value = index;
    tabController.animateTo(index);
  }

  Future<void> fetchLiveMatches() async {
    try {
      isLoadingLiveMatches.value = true;
      final response = await _leagueRepository.getAllScheduleLiveMatches(
        matchStatus: 'live',
        leagueId: leagueId ?? '',
      );
      liveMatches.value = response;
    } catch (e) {
      print('Error fetching live matches: $e');
    } finally {
      isLoadingLiveMatches.value = false;
    }
  }

  Future<void> fetchUpcomingMatches() async {
    try {
      isLoadingUpcomingMatches.value = true;
      final response = await _leagueRepository.getAllScheduleLiveMatches(
        matchStatus: 'upcoming',
        leagueId: leagueId ?? '',
      );
      upcomingMatches.value = response;
    } catch (e) {
      print('Error fetching upcoming matches: $e');
    } finally {
      isLoadingUpcomingMatches.value = false;
    }
  }

  Future<void> fetchResultMatches() async {
    try {
      isLoadingResultMatches.value = true;
      final response = await _leagueRepository.getAllScheduleLiveMatches(
        matchStatus: 'finished',
        leagueId: leagueId ?? '',
      );
      resultMatches.value = response;
    } catch (e) {
      print('Error fetching result matches: $e');
    } finally {
      isLoadingResultMatches.value = false;
    }
  }

  Future<void> fetchSponsors() async {
    try {
      isLoadingSponsors.value = true;
      final response = await _leagueRepository.getLeagueSponsors(leagueId: leagueId);
      print('🎯 Sponsors - leagueId: $leagueId, data: ${response.data?.titleSponsor?.titleSponsorBanner}, sponsors count: ${response.data?.sponsors?.length}');
      sponsors.value = response;
    } catch (e) {
      print('Error fetching sponsors: $e');
    } finally {
      isLoadingSponsors.value = false;
    }
  }

  Future<void> fetchLeaderBoard() async {
    try {
      isLoadingLeaderBoard.value = true;
      final response = await _leagueRepository.getLeagueLeaderBoard(
        leagueId: leagueId ?? '',
      );
      leaderBoard.value = response;
    } catch (e) {
      print('Error fetching leaderboard: $e');
    } finally {
      isLoadingLeaderBoard.value = false;
    }
  }
}