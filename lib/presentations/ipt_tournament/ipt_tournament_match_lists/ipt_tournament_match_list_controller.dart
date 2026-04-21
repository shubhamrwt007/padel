import 'package:padel_mobile/core/network/dio_client.dart';
import 'package:padel_mobile/presentations/auth/forgot_password/widgets/forgot_password_exports.dart';
import 'package:padel_mobile/repositories/league_repository/league_repository.dart';
import 'package:padel_mobile/data/response_models/league/get_all_schedule_live_matches_model.dart';

class IptTournamentListController extends GetxController{
  final RxString matchStatus = ''.obs;
  final RxBool isHistoryEnabled = false.obs;
  final RxString leagueId = ''.obs;
  final LeagueRepository _leagueRepository = LeagueRepository();
  final Rx<GetAllScheduleLiveMatchesModel?> upcomingMatches = Rx<GetAllScheduleLiveMatchesModel?>(null);
  final RxBool isLoadingUpcomingMatches = false.obs;
  final Rx<GetAllScheduleLiveMatchesModel?> resultMatches = Rx<GetAllScheduleLiveMatchesModel?>(null);
  final RxBool isLoadingResultMatches = false.obs;
  
  final RxInt upcomingPage = 1.obs;
  final RxInt resultPage = 1.obs;
  final RxBool hasMoreUpcoming = true.obs;
  final RxBool hasMoreResult = true.obs;
  final RxBool isLoadingMoreUpcoming = false.obs;
  final RxBool isLoadingMoreResult = false.obs;
  
  final RxString selectedFilter = 'all'.obs;
  final RxString selectedDate = ''.obs;
  final RxString selectedCategory = ''.obs;
  final RxList<String> availableDates = <String>[].obs;
  final RxList<String> availableCategories = <String>[].obs;
  
@override
  void onInit() {
    leagueId.value = Get.arguments['leagueId'] ?? '';
    final initialTab = Get.arguments['initialTab'] ?? 0;
    if (initialTab == 1) {
      isHistoryEnabled.value = true;
      matchStatus.value = 'finished';
    }
    fetchScheduleDates();
    if (matchStatus.value == 'finished') {
      fetchResultMatches();
    } else {
      fetchUpcomingMatches();
    }
    super.onInit();
  }
  
  void switchToHistory() {
    isHistoryEnabled.value = !isHistoryEnabled.value;
    if (isHistoryEnabled.value) {
      matchStatus.value = 'finished';
      fetchScheduleDates();
      fetchResultMatches();
    } else {
      matchStatus.value = '';
      fetchScheduleDates();
      fetchUpcomingMatches();
    }
  }
  
  void updateFilter(String filter) {
    selectedFilter.value = filter;
    upcomingPage.value = 1;
    resultPage.value = 1;
    hasMoreUpcoming.value = true;
    hasMoreResult.value = true;
    fetchScheduleDates();
    if (matchStatus.value == '') {
      fetchUpcomingMatches();
    } else {
      fetchResultMatches();
    }
  }
  
  void updateDate(String date) {
    selectedDate.value = date;
    upcomingPage.value = 1;
    resultPage.value = 1;
    hasMoreUpcoming.value = true;
    hasMoreResult.value = true;
    if (matchStatus.value == '') {
      fetchUpcomingMatches();
    } else {
      fetchResultMatches();
    }
  }
  
  void updateCategory(String category) {
    selectedCategory.value = category;
    upcomingPage.value = 1;
    resultPage.value = 1;
    hasMoreUpcoming.value = true;
    hasMoreResult.value = true;
    if (matchStatus.value == '') {
      fetchUpcomingMatches();
    } else {
      fetchResultMatches();
    }
  }
  
  Future<void> fetchScheduleDates() async {
    try {
      final response = await _leagueRepository.getScheduleDates(
        leagueId: leagueId.value,
        matchStatus: matchStatus.value,
      );
      availableDates.value = response.data ?? [];
      if (response.categories != null) {
        availableCategories.value = response.categories ?? [];
      }
    } catch (e) {
      print('Error fetching schedule dates: $e');
    }
  }
  
  Future<void> fetchUpcomingMatches() async {
    try {
      isLoadingUpcomingMatches.value = true;
      upcomingPage.value = 1;
      final userId = selectedFilter.value == 'my' ? storage.read("userId")??"": null;
      final response = await _leagueRepository.getAllScheduleLiveMatches(
        matchStatus: '',
        leagueId: leagueId.value,
        userId: userId?.isNotEmpty == true ? userId : null,
        date: selectedDate.value.isNotEmpty ? selectedDate.value : null,
        categoryType: selectedCategory.value,
        page: 1,
        limit: 10
      );
      upcomingMatches.value = response;
      hasMoreUpcoming.value = (response.data?.length ?? 0) >= 10;
    } catch (e) {
      print('Error fetching upcoming matches: $e');
    } finally {
      isLoadingUpcomingMatches.value = false;
    }
  }
  
  Future<void> loadMoreUpcoming() async {
    if (isLoadingMoreUpcoming.value || !hasMoreUpcoming.value) return;
    try {
      isLoadingMoreUpcoming.value = true;
      upcomingPage.value++;
      final userId = selectedFilter.value == 'my' ? storage.read("userId")??"": null;
      final response = await _leagueRepository.getAllScheduleLiveMatches(
        matchStatus: '',
        leagueId: leagueId.value,
        userId: userId?.isNotEmpty == true ? userId : null,
        date: selectedDate.value.isNotEmpty ? selectedDate.value : null,
        categoryType: selectedCategory.value,
        page: upcomingPage.value,
        limit: 10
      );
      if (response.data?.isNotEmpty == true) {
        upcomingMatches.value?.data?.addAll(response.data!);
        upcomingMatches.refresh();
        hasMoreUpcoming.value = (response.data?.length ?? 0) >= 10;
      } else {
        hasMoreUpcoming.value = false;
      }
    } catch (e) {
      print('Error loading more upcoming matches: $e');
    } finally {
      isLoadingMoreUpcoming.value = false;
    }
  }

  Future<void> fetchResultMatches() async {
    try {
      isLoadingResultMatches.value = true;
      resultPage.value = 1;
      final userId = selectedFilter.value == 'my' ? storage.read("userId")??"" : null;
      final response = await _leagueRepository.getAllScheduleLiveMatches(
        matchStatus: 'finished',
        leagueId: leagueId.value,
        userId: userId?.isNotEmpty == true ? userId : null,
        date: selectedDate.value.isNotEmpty ? selectedDate.value : null,
        categoryType: selectedCategory.value,
        page: 1,
        limit: 10
      );
      resultMatches.value = response;
      hasMoreResult.value = (response.data?.length ?? 0) >= 10;
    } catch (e) {
      print('Error fetching result matches: $e');
    } finally {
      isLoadingResultMatches.value = false;
    }
  }
  
  Future<void> loadMoreResult() async {
    if (isLoadingMoreResult.value || !hasMoreResult.value) return;
    try {
      isLoadingMoreResult.value = true;
      resultPage.value++;
      final userId = selectedFilter.value == 'my' ? storage.read("userId")??"" : null;
      final response = await _leagueRepository.getAllScheduleLiveMatches(
        matchStatus: 'finished',
        leagueId: leagueId.value,
        userId: userId?.isNotEmpty == true ? userId : null,
        date: selectedDate.value.isNotEmpty ? selectedDate.value : null,
        categoryType: selectedCategory.value,
        page: resultPage.value,
        limit: 10
      );
      if (response.data?.isNotEmpty == true) {
        resultMatches.value?.data?.addAll(response.data!);
        resultMatches.refresh();
        hasMoreResult.value = (response.data?.length ?? 0) >= 10;
      } else {
        hasMoreResult.value = false;
      }
    } catch (e) {
      print('Error loading more result matches: $e');
    } finally {
      isLoadingMoreResult.value = false;
    }
  }

}