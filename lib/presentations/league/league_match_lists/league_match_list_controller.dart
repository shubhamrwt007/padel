import 'package:padel_mobile/core/network/dio_client.dart';
import 'package:padel_mobile/presentations/auth/forgot_password/widgets/forgot_password_exports.dart';
import 'package:padel_mobile/repositories/league_repository/league_repository.dart';
import 'package:padel_mobile/data/response_models/league/get_all_schedule_live_matches_model.dart';

class LeagueMatchListController extends GetxController{
  final matchTab = 0.obs;
  final RxString leagueId = ''.obs;
  final LeagueRepository _leagueRepository = LeagueRepository();
  final Rx<GetAllScheduleLiveMatchesModel?> upcomingMatches = Rx<GetAllScheduleLiveMatchesModel?>(null);
  final RxBool isLoadingUpcomingMatches = false.obs;
  final Rx<GetAllScheduleLiveMatchesModel?> resultMatches = Rx<GetAllScheduleLiveMatchesModel?>(null);
  final RxBool isLoadingResultMatches = false.obs;
  
  final RxString selectedFilter = 'all'.obs;
  final RxString selectedDate = ''.obs;
  final RxList<String> availableDates = <String>[].obs;
  
@override
  void onInit() {
    matchTab.value = Get.arguments['matchTab'];
    leagueId.value = Get.arguments['leagueId'] ?? '';
    fetchScheduleDates();
    if (matchTab.value == 0) {
      fetchUpcomingMatches();
    } else if (matchTab.value == 2) {
      fetchResultMatches();
    }
    super.onInit();
  }
  
  void updateFilter(String filter) {
    selectedFilter.value = filter;
    fetchScheduleDates();
    if (matchTab.value == 0) {
      fetchUpcomingMatches();
    } else if (matchTab.value == 2) {
      fetchResultMatches();
    }
  }
  
  void updateDate(String date) {
    selectedDate.value = date;
    if (matchTab.value == 0) {
      fetchUpcomingMatches();
    } else if (matchTab.value == 2) {
      fetchResultMatches();
    }
  }
  
  Future<void> fetchScheduleDates() async {
    try {
      final matchStatus = matchTab.value == 0 ? 'upcoming' : 'finished';
      final response = await _leagueRepository.getScheduleDates(
        leagueId: leagueId.value,
        matchStatus: matchStatus,
      );
      availableDates.value = response.data ?? [];
    } catch (e) {
      print('Error fetching schedule dates: $e');
    }
  }
  
  Future<void> fetchUpcomingMatches() async {
    try {
      isLoadingUpcomingMatches.value = true;
      final userId = selectedFilter.value == 'my' ? storage.read("userId")??"": null;
      final response = await _leagueRepository.getAllScheduleLiveMatches(
        matchStatus: 'upcoming',
        leagueId: leagueId.value,
        userId: userId?.isNotEmpty == true ? userId : null,
        date: selectedDate.value.isNotEmpty ? selectedDate.value : null,
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
      final userId = selectedFilter.value == 'my' ? storage.read("userId")??"" : null;
      final response = await _leagueRepository.getAllScheduleLiveMatches(
        matchStatus: 'finished',
        leagueId: leagueId.value,
        userId: userId?.isNotEmpty == true ? userId : null,
        date: selectedDate.value.isNotEmpty ? selectedDate.value : null,
      );
      resultMatches.value = response;
    } catch (e) {
      print('Error fetching result matches: $e');
    } finally {
      isLoadingResultMatches.value = false;
    }
  }

}