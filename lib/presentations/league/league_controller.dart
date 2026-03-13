import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/repositories/league_repository/league_repository.dart';
import 'package:padel_mobile/data/response_models/league/get_all_schedule_live_matches_model.dart';
import 'package:padel_mobile/data/response_models/league/get_league_sponsors_model.dart';

class LeagueController extends GetxController with GetSingleTickerProviderStateMixin {
  final RxInt selectedTab = 0.obs;
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

  @override
  void onInit() {
    super.onInit();
    pageController = PageController(initialPage: 1);
    tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    fetchLiveMatches();
    fetchUpcomingMatches();
    fetchResultMatches();
    fetchSponsors();
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
      final response = await _leagueRepository.getAllScheduleLiveMatches(matchStatus: 'live');
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
      final response = await _leagueRepository.getAllScheduleLiveMatches(matchStatus: 'upcoming');
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
      final response = await _leagueRepository.getAllScheduleLiveMatches(matchStatus: 'finished');
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
      final response = await _leagueRepository.getLeagueSponsors();
      sponsors.value = response;
    } catch (e) {
      print('Error fetching sponsors: $e');
    } finally {
      isLoadingSponsors.value = false;
    }
  }
}