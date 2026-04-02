import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';
import 'package:padel_mobile/core/network/dio_client.dart';
import 'package:padel_mobile/data/request_models/home_models/get_category_model.dart';
import 'package:padel_mobile/data/response_models/league/get_league_list_model.dart';
import 'package:padel_mobile/data/response_models/openmatch_model/open_match_booking_model.dart';
import 'package:padel_mobile/presentations/profile/profile_controller.dart';
import 'package:padel_mobile/presentations/home/home_controller.dart';
import 'package:padel_mobile/repositories/home_repository/home_repository.dart';
import 'package:padel_mobile/repositories/openmatches/open_match_repository.dart';
import 'package:padel_mobile/data/response_models/home_models/get_near_city_players_model.dart';
import 'package:padel_mobile/generated/assets.dart';
import 'package:padel_mobile/repositories/league_repository/league_repository.dart';
import 'package:padel_mobile/data/response_models/league/get_all_schedule_live_matches_model.dart';
import 'package:padel_mobile/data/response_models/league/get_league_sponsors_model.dart';
import 'package:padel_mobile/data/response_models/league/get_league_poll_results_model.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class MainHomeController extends GetxController {
  final ProfileController profileController = Get.put(ProfileController());
  final HomeController homeController = Get.put(HomeController());
  final HomeRepository _homeRepository = HomeRepository();
  final OpenMatchRepository _openMatchRepository = OpenMatchRepository();
  final LeagueRepository _leagueRepository = LeagueRepository();

  final Rx<GetNearCityPlayers?> nearCityPlayers = Rx<GetNearCityPlayers?>(null);
  final RxBool isLoadingPlayers = false.obs;
  final RxInt leagueLiveCarouselIndex = 0.obs;
  final Rx<GetAllScheduleLiveMatchesModel?> scheduleMatches = Rx<GetAllScheduleLiveMatchesModel?>(null);
  final RxBool isLoadingScheduleMatches = false.obs;
  final Rx<GetAllScheduleLiveMatchesModel?> upcomingMatches = Rx<GetAllScheduleLiveMatchesModel?>(null);
  final RxBool isLoadingUpcomingMatches = false.obs;
  final RxBool isLoadingLeagueSection = false.obs;
  final Rx<GetLeagueListModel?> activeLeagues = Rx<GetLeagueListModel?>(null);
  final RxBool isLoadingActiveLeagues = false.obs;
  final RxInt leagueCarouselIndex = 0.obs;
  final RxInt selectedSportTab = 0.obs;
  final Rx<GetCategoryModel?> categoryModel = Rx<GetCategoryModel?>(null);
  final RxBool isLoadingCategory = false.obs;
  final RxString selectedCategoryId = ''.obs;
  final Rx<OpenMatchBookingModel?> openMatches = Rx<OpenMatchBookingModel?>(null);
  final RxBool isLoadingOpenMatches = false.obs;
  final RxInt currentBannerIndex = 0.obs;
  var customerRank = 0.obs;
  final Rx<GetLeaguePollResultsModel?> pollResults = Rx<GetLeaguePollResultsModel?>(null);
  final RxBool isLoadingPoll = false.obs;

  final List<String> padelBannerImages = [
    Assets.imagesNewHomeBanner,
    Assets.imagesNewHomeBanner2,
    Assets.imagesNewHomeBanner7,
    Assets.imagesNewHomeBanner6,
  ];

  final List<String> pickleballBannerImages = [
    Assets.imagesNewHomeBanner4,
    Assets.imagesNewHomeBanner5,
  ];

  List<String> get bannerImages => selectedSportTab.value == 0 ? padelBannerImages : pickleballBannerImages;

  void clearAllData() {
    openMatches.value = null;
    nearCityPlayers.value = null;
    customerRank.value = 0;
    currentBannerIndex.value = 0;
    selectedSportTab.value = 0;
    selectedCategoryId.value = '';
    homeController.clearAllData();
  }

  @override
  void onInit() {
    super.onInit();
    clearAllData();
    _initData();
  }

  Future<void> _initData() async {
    await fetchCategories();
    isLoadingLeagueSection.value = true;
    await fetchActiveLeagues();

    final locationId = profileController.profileModel.value?.response?.city?.sId ?? "68c94a94d72a6f9769712ff0";

    await Future.wait([
      homeController.fetchBookings(
        categoryId: selectedCategoryId.value.isNotEmpty ? selectedCategoryId.value : null,
        locationId: locationId,
      ),
      fetchNearCityPlayers(),
      fetCustomerLeaderBoardRank(),
      fetchOpenMatches(),
      _fetchLeagueData(),
      fetchPollResults(),
    ]);
    isLoadingLeagueSection.value = false;
  }

  Future<void> _fetchLeagueData() async {
    await Future.wait([
      fetchScheduleMatches(),
      fetchUpcomingMatches(),
    ]);
  }

  @override
  void onClose() {
    super.onClose();
  }

  void onSportTabChanged(int index) async {
    selectedSportTab.value = index;
    currentBannerIndex.value = 0;

    final categories = categoryModel.value?.data ?? [];
    if (categories.isEmpty) return;

    String? categoryId;
    if (index == 0 && categories.isNotEmpty) {
      final padelCategory = categories.firstWhere(
        (cat) => cat.name?.toLowerCase() == 'padel',
        orElse: () => categories.first,
      );
      categoryId = padelCategory.sId;
    } else if (index == 1 && categories.length > 1) {
      final pickleballCategory = categories.firstWhere(
        (cat) => cat.name?.toLowerCase() == 'pickleball',
        orElse: () => categories.last,
      );
      categoryId = pickleballCategory.sId;
    }

    selectedCategoryId.value = categoryId ?? '';

    final locationId = profileController.profileModel.value?.response?.city?.sId ?? "68c94a94d72a6f9769712ff0";

    homeController.currentPage.value = 1;
    homeController.fetchClubs(
      isRefresh: true,
      categoryId: selectedCategoryId.value,
      locationId: locationId,
    );

    await Future.wait([
      homeController.fetchBookings(
        categoryId: selectedCategoryId.value,
        locationId: locationId,
      ),
      fetchOpenMatches(),
    ]);
  }

  Future<void> fetchOpenMatches() async {
    try {
      isLoadingOpenMatches.value = true;
      final userId = storage.read('userId') ?? '';
      final formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final locationId = profileController.profileModel.value?.response?.city?.sId ?? "68c94a94d72a6f9769712ff0";

      final response = await _openMatchRepository.getOpenMatchBookings(
        userid: userId,
        filter: 'allMatches',
        type: 'upcoming',
        matchDate: formattedDate,
        locationId: locationId,
        categoryId: selectedCategoryId.value.isNotEmpty ? selectedCategoryId.value : null,
      );

      openMatches.value = response;
    } catch (e) {
      // ignore
    } finally {
      isLoadingOpenMatches.value = false;
    }
  }

  Future<void> fetchNearCityPlayers() async {
    try {
      isLoadingPlayers.value = true;
      final userId = storage.read('userId') ?? "";
      final response = await _homeRepository.getNearCityPlayers(id: userId);
      nearCityPlayers.value = response;
    } catch (e) {
      // ignore
    } finally {
      isLoadingPlayers.value = false;
    }
  }

  Future<void> fetchCategories() async {
    try {
      isLoadingCategory.value = true;
      final response = await _homeRepository.getCategory();
      categoryModel.value = response;

      final categories = response.data ?? [];
      if (categories.isNotEmpty) {
        final padelCategory = categories.firstWhere(
          (cat) => cat.name?.toLowerCase() == 'padel',
          orElse: () => categories.first,
        );
        selectedCategoryId.value = padelCategory.sId ?? '';

        final locationId = profileController.profileModel.value?.response?.city?.sId ?? "68c94a94d72a6f9769712ff0";
        homeController.fetchClubs(
          isRefresh: true,
          categoryId: selectedCategoryId.value,
          locationId: locationId,
        );
      }
    } catch (e) {
      // ignore
    } finally {
      isLoadingCategory.value = false;
    }
  }

  Future<void> fetCustomerLeaderBoardRank() async {
    try {
      final userId = storage.read('userId') ?? "";
      final response = await _homeRepository.getCustomerLeaderBoardRank(id: userId);
      if (response.success == true) {
        customerRank.value = response.rank ?? 0;
      }
    } catch (e) {
      // ignore
    }
  }

  void onBannerTap(int index) {
    Get.toNamed(RoutesName.bookACourt);
  }

  Future<void> fetchScheduleMatches() async {
    try {
      isLoadingScheduleMatches.value = true;
      final leagueId = activeLeagues.value?.data?.firstOrNull?.id ?? '';
      final response = await _leagueRepository.getAllScheduleLiveMatches(matchStatus: 'live', leagueId: leagueId);
      scheduleMatches.value = response;
    } catch (e) {
      // ignore
    } finally {
      isLoadingScheduleMatches.value = false;
    }
  }

  Future<void> fetchUpcomingMatches() async {
    try {
      isLoadingUpcomingMatches.value = true;
      final leagueId = activeLeagues.value?.data?.firstOrNull?.id ?? '';
      final response = await _leagueRepository.getAllScheduleLiveMatches(matchStatus: 'upcoming', leagueId: leagueId);
      upcomingMatches.value = response;
    } catch (e) {
      // ignore
    } finally {
      isLoadingUpcomingMatches.value = false;
    }
  }

  Future<void> fetchActiveLeagues() async {
    try {
      isLoadingActiveLeagues.value = true;
      final response = await _leagueRepository.getLeagueList(status: 'active');
      activeLeagues.value = response;
    } catch (e) {
      // ignore
    } finally {
      isLoadingActiveLeagues.value = false;
    }
  }

  Future<void> fetchPollResults() async {
    try {
      isLoadingPoll.value = true;
      final response = await _leagueRepository.getLeaguePollResult();
      pollResults.value = response;
    } catch (e) {
      // ignore
    } finally {
      isLoadingPoll.value = false;
    }
  }

  Future<bool> castVote({required String clubId, required String clubName}) async {
    try {
      final pollId = pollResults.value?.data?.poll?.id ?? '';
      final userId = storage.read('userId') ?? '';
      String deviceId = '';
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        deviceId = (await deviceInfo.androidInfo).id;
      } else if (Platform.isIOS) {
        deviceId = (await deviceInfo.iosInfo).identifierForVendor ?? '';
      }
      await _leagueRepository.castLeagueVote(data: {
        'pollId': pollId,
        'clubId': clubId,
        'deviceId': deviceId,
      });
      // Refresh poll results silently
      final response = await _leagueRepository.getLeaguePollResult();
      pollResults.value = response;
      return true;
    } catch (e) {
      return false;
    }
  }
}
