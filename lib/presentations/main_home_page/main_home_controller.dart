import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';
import 'package:padel_mobile/core/network/dio_client.dart';
import 'package:padel_mobile/data/request_models/home_models/get_category_model.dart';
import 'package:padel_mobile/data/response_models/ipt_tournament/get_ipt_tournament_list_model.dart';
import 'package:padel_mobile/data/response_models/league/get_league_list_model.dart';
import 'package:padel_mobile/data/response_models/openmatch_model/open_match_booking_model.dart';
import 'package:padel_mobile/presentations/profile/profile_controller.dart';
import 'package:padel_mobile/presentations/home/home_controller.dart';
import 'package:padel_mobile/repositories/home_repository/home_repository.dart';
import 'package:padel_mobile/repositories/ipt_tournament_repository/ipt_tournament_repository.dart';
import 'package:padel_mobile/repositories/openmatches/open_match_repository.dart';
import 'package:padel_mobile/data/response_models/home_models/get_near_city_players_model.dart';
import 'package:padel_mobile/generated/assets.dart';
import 'package:padel_mobile/repositories/league_repository/league_repository.dart';
import 'package:padel_mobile/data/response_models/league/get_all_schedule_live_matches_model.dart';
import 'package:padel_mobile/data/response_models/league/get_league_sponsors_model.dart';
import 'package:padel_mobile/data/response_models/league/get_league_poll_results_model.dart';
import 'package:padel_mobile/data/response_models/league/get_league_leader_board_model.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:padel_mobile/repositories/authentication_repository/sign_up_repository.dart';
import 'package:padel_mobile/repositories/home_repository/profile_repository.dart';
import 'package:padel_mobile/data/response_models/get_locations_model.dart';
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
  final Rx<GetIptTournamentListModel?> activeTournaments = Rx<GetIptTournamentListModel?>(null);
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
  final Rx<GetLeagueLeaderBoardModel?> leaderBoard = Rx<GetLeagueLeaderBoardModel?>(null);
  final RxBool isLoadingLeaderBoard = false.obs;

  final RxString selectedLocationId = ''.obs;
  final RxString selectedLocation = ''.obs;
  var locations = <GetLocationData>[].obs;
  var isLocationLoading = false.obs;
  final SignUpRepository _signUpRepository = SignUpRepository();
  final ProfileRepository _profileRepository = ProfileRepository();

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

  void checkAndShowCityPopup() {
    final isCityNull = profileController.profileModel.value?.isCityNull ?? false;
    if (isCityNull) {
      Future.delayed(Duration(milliseconds: 500), () {
        _showCitySelectionDialog();
      });
    }
  }

  Future<void> fetchLocations() async {
    isLocationLoading.value = true;
    try {
      final response = await _signUpRepository.getLocations();
      if (response.status == true) {
        locations.assignAll(response.data?.toList() ?? []);
      }
    } catch (e) {
      // ignore
    } finally {
      isLocationLoading.value = false;
    }
  }

  Future<void> updateCityOnly() async {
    if (selectedLocationId.value.isEmpty) return;
    
    try {
      isLocationLoading.value = true;
      
      Map<String, dynamic> locationJson = {
        "type": "Point",
        "coordinates": [77.5947, 12.9717],
      };

      final updatedProfile = await _profileRepository.updateUserProfile(
        city: selectedLocationId.value,
        location: locationJson,
      );

      if (updatedProfile.status == "200") {
        await profileController.fetchUserProfile();
        Get.back();
        print('✅ City updated successfully');
      }
    } catch (e) {
      print('❌ Failed to update city: $e');
    } finally {
      isLocationLoading.value = false;
    }
  }

  void _showCitySelectionDialog() async {
    await fetchLocations();
    
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, size: 48, color: Get.theme.primaryColor),
                SizedBox(height: 16),
                Text(
                  'Select Your City',
                  style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  'Please select your city to continue',
                  textAlign: TextAlign.center,
                  style: Get.textTheme.bodyMedium,
                ),
                SizedBox(height: 24),
                Obx(() {
                  if (isLocationLoading.value) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(5),
                        color: Color(0xFFF5F5F5),
                      ),
                      child: Row(
                        children: [
                          CupertinoActivityIndicator(color: Get.theme.primaryColor, radius: 14),
                          SizedBox(width: 12),
                          Text('Loading Locations...', style: Get.textTheme.headlineMedium?.copyWith(color: Color(0xFF252525), fontWeight: FontWeight.w500)),
                        ],
                      ),
                    );
                  }

                  if (locations.isEmpty) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(5),
                        color: Color(0xFFF5F5F5),
                      ),
                      child: Text('No Location found', style: Get.textTheme.headlineMedium?.copyWith(color: Color(0xFF252525), fontWeight: FontWeight.w500)),
                    );
                  }

                  return DropdownButtonFormField<String>(
                    value: selectedLocation.value.isEmpty ? null : selectedLocation.value,
                    style: Get.textTheme.headlineMedium?.copyWith(color: Color(0xFF252525), fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      labelText: "Location / City",
                      labelStyle: Get.textTheme.headlineMedium?.copyWith(color: Color(0xFF252525), fontWeight: FontWeight.w500),
                      filled: true,
                      fillColor: Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide(color: Colors.grey, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide(color: Colors.grey, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide(color: Get.theme.primaryColor, width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: Get.width * 0.04,
                        vertical: 57 * 0.22,
                      ),
                    ),
                    hint: Text('Select Location', style: Get.textTheme.headlineMedium?.copyWith(color: Color(0xFF252525), fontWeight: FontWeight.w500)),
                    dropdownColor: Colors.white,
                    isExpanded: true,
                    items: locations.map((location) {
                      return DropdownMenuItem<String>(
                        value: location.name ?? '',
                        child: Text(
                          location.name ?? '',
                          style: Get.textTheme.headlineMedium?.copyWith(color: Color(0xFF252525), fontWeight: FontWeight.w500),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      selectedLocation.value = value ?? '';
                      final selectedLoc = locations.firstWhere(
                        (loc) => loc.name == value,
                        orElse: () => GetLocationData(),
                      );
                      selectedLocationId.value = selectedLoc.id ?? '';
                      print('Selected Location -> ${selectedLocation.value}, ID -> ${selectedLocationId.value}');
                    },
                  );
                }),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('Cancel'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Obx(() => ElevatedButton(
                        onPressed: isLocationLoading.value ? null : () => updateCityOnly(),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: isLocationLoading.value
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text('OK'),
                      )),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _initData() async {
    await fetchCategories();
    isLoadingLeagueSection.value = true;
    await fetchActiveLeagues();
    await fetchActiveTournaments();

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
      fetchLeaderBoard(),
    ]);
    isLoadingLeagueSection.value = false;
    
    checkAndShowCityPopup();
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
        // locationId: locationId,
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
  final IptTournamentRepository _iptTournamentRepository = Get.put(IptTournamentRepository());
  Future<void> fetchActiveTournaments() async {
    try {
      isLoadingActiveLeagues.value = true;
      final response = await _iptTournamentRepository.getIptTournamentList(status: 'active');
      activeTournaments.value = response;
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

  Future<void> fetchLeaderBoard() async {
    try {
      isLoadingLeaderBoard.value = true;
      final leagueId = activeLeagues.value?.data?.firstOrNull?.id ?? '';
      final response = await _leagueRepository.getLeagueLeaderBoard(
        leagueId: leagueId,
      );
      leaderBoard.value = response;
    } catch (e) {
      // ignore
    } finally {
      isLoadingLeaderBoard.value = false;
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
