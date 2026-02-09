import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';
import 'package:padel_mobile/core/network/dio_client.dart';
import 'package:padel_mobile/data/request_models/home_models/get_category_model.dart';
import 'package:padel_mobile/data/response_models/openmatch_model/open_match_booking_model.dart';
import 'package:padel_mobile/presentations/profile/profile_controller.dart';
import 'package:padel_mobile/presentations/home/home_controller.dart';
import 'package:padel_mobile/repositories/home_repository/home_repository.dart';
import 'package:padel_mobile/repositories/openmatches/open_match_repository.dart';
import 'package:padel_mobile/data/response_models/home_models/get_near_city_players_model.dart';
import 'package:padel_mobile/generated/assets.dart';
class MainHomeController extends GetxController{
  final ProfileController profileController = Get.put(ProfileController());
  final HomeController homeController = Get.put(HomeController());
  final HomeRepository _homeRepository = HomeRepository();
  final OpenMatchRepository _openMatchRepository = OpenMatchRepository();
  final Rx<GetNearCityPlayers?> nearCityPlayers = Rx<GetNearCityPlayers?>(null);
  final RxBool isLoadingPlayers = false.obs;
  // Sport Tab Selection
  final RxInt selectedSportTab = 0.obs; // 0 = Padel, 1 = Pickleball
  
  // Category data
  final Rx<GetCategoryModel?> categoryModel = Rx<GetCategoryModel?>(null);
  final RxBool isLoadingCategory = false.obs;
  final RxString selectedCategoryId = ''.obs;
  
  // Open Matches
  final Rx<OpenMatchBookingModel?> openMatches = Rx<OpenMatchBookingModel?>(null);
  final RxBool isLoadingOpenMatches = false.obs;

  // Banner functionality
  final RxInt currentBannerIndex = 0.obs;
  Timer? _bannerTimer;
  late PageController pageController;

  final List<String> padelBannerImages = [
    Assets.imagesNewHomeBanner,
    Assets.imagesNewHomeBanner2,
    Assets.imagesNewHomeBanner4,
    Assets.imagesNewHomeBanner5,
  ];

  final List<String> pickleballBannerImages = [
    Assets.imagesNewHomeBanner7,
    Assets.imagesNewHomeBanner6,
  ];

  List<String> get bannerImages => selectedSportTab.value == 0 ? padelBannerImages : pickleballBannerImages;

  @override
  void onInit() async {
    super.onInit();
    pageController = PageController(initialPage: 1000);
    
    // Fetch categories first and wait for it to complete
    await fetchCategories();
    
    // Now fetch bookings with the selected category and location
    final locationId = profileController.profileModel.value?.response?.city?.sId ?? "68c94a94d72a6f9769712ff0";
    
    print("🔍 OnInit - CategoryId: ${selectedCategoryId.value}, LocationId: $locationId");
    
    await homeController.fetchBookings(
      categoryId: selectedCategoryId.value.isNotEmpty ? selectedCategoryId.value : null,
      locationId: locationId,
    );
    
    await fetchNearCityPlayers();
    await fetCustomerLeaderBoardRank();
    await fetchOpenMatches();
    _startBannerAutoSlide();
  }

  @override
  void onClose() {
    _bannerTimer?.cancel();
    pageController.dispose();
    super.onClose();
  }

  void _startBannerAutoSlide() {
    _bannerTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (pageController.hasClients) {
        pageController.nextPage(
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  /// Handle sport tab changes
  void onSportTabChanged(int index) async {
    selectedSportTab.value = index;
    
    // Reset banner to first page when switching tabs
    currentBannerIndex.value = 0;
    if (pageController.hasClients) {
      pageController.jumpToPage(1000);
    }
    
    final categories = categoryModel.value?.data ?? [];
    if (categories.isEmpty) return;
    
    String? categoryId;
    if (index == 0 && categories.isNotEmpty) {
      // Padel - find padel category
      final padelCategory = categories.firstWhere(
        (cat) => cat.name?.toLowerCase() == 'padel',
        orElse: () => categories.first,
      );
      categoryId = padelCategory.sId;
    } else if (index == 1 && categories.length > 1) {
      // Pickleball - find pickleball category
      final pickleballCategory = categories.firstWhere(
        (cat) => cat.name?.toLowerCase() == 'pickleball',
        orElse: () => categories.last,
      );
      categoryId = pickleballCategory.sId;
    }
    
    selectedCategoryId.value = categoryId ?? '';
    
    // Get location ID from profile
    final locationId = profileController.profileModel.value?.response?.city?.sId ?? "68c94a94d72a6f9769712ff0";
    
    // Fetch clubs with category and location
    homeController.currentPage.value = 1;
    homeController.fetchClubs(
      isRefresh: true,
      categoryId: selectedCategoryId.value,
      locationId: locationId,
    );
    
    // Fetch bookings with category and location
    await homeController.fetchBookings(
      categoryId: selectedCategoryId.value,
      locationId: locationId,
    );
    
    // Fetch open matches with category
    await fetchOpenMatches();
  }
  
  Future<void> fetchOpenMatches() async {
    try {
      isLoadingOpenMatches.value = true;
      final userId = storage.read('userId') ?? '';
      final formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final locationId = profileController.profileModel.value?.response?.city?.sId ?? "68c94a94d72a6f9769712ff0";
      
      print("🎾 Fetching Open Matches - CategoryId: ${selectedCategoryId.value}, LocationId: $locationId");
      
      final response = await _openMatchRepository.getOpenMatchBookings(
        userid: userId,
        filter: 'allMatches',
        type: 'upcoming',
        matchDate: formattedDate,
        locationId: locationId,
        categoryId: selectedCategoryId.value.isNotEmpty ? selectedCategoryId.value : null,
      );
      
      openMatches.value = response;
      print("🎾 Open Matches Fetched: ${response?.data?.length ?? 0} matches");
    } catch (e) {
      print('Error fetching open matches: $e');
    } finally {
      isLoadingOpenMatches.value = false;
    }
  }
  Future<void> fetchNearCityPlayers() async {
    try {
      isLoadingPlayers.value = true;
      final userId = storage.read('userId')??"";
      if (userId != null) {
        final response = await _homeRepository.getNearCityPlayers(id: userId);
        nearCityPlayers.value = response;
      }
    } catch (e) {
      print('Error fetching near city players: $e');
    } finally {
      isLoadingPlayers.value = false;
    }
  }
  
  Future<void> fetchCategories() async {
    try {
      isLoadingCategory.value = true;
      final response = await _homeRepository.getCategory();
      categoryModel.value = response;
      
      // Set default to Padel category
      final categories = response.data ?? [];
      if (categories.isNotEmpty) {
        final padelCategory = categories.firstWhere(
          (cat) => cat.name?.toLowerCase() == 'padel',
          orElse: () => categories.first,
        );
        selectedCategoryId.value = padelCategory.sId ?? '';
        
        print("🎯 Selected Category: ${padelCategory.name}, ID: ${selectedCategoryId.value}");
        
        // Fetch clubs with padel category and dynamic location
        final locationId = profileController.profileModel.value?.response?.city?.sId ?? "68c94a94d72a6f9769712ff0";
        homeController.fetchClubs(
          isRefresh: true,
          categoryId: selectedCategoryId.value,
          locationId: locationId,
        );
      }
    } catch (e) {
      print('Error fetching categories: $e');
    } finally {
      isLoadingCategory.value = false;
    }
  }

  var customerRank = 0.obs;
  Future<void> fetCustomerLeaderBoardRank() async {
    try {
      isLoadingPlayers.value = true;
      final userId = storage.read('userId')??"";
      if (userId != null) {
        final response = await _homeRepository.getCustomerLeaderBoardRank(id: userId);
        if(response.success == true){
          customerRank.value = response.rank??0;
          print(response);
        }
      }
    } catch (e) {
      print('Error fetching Customer Rank: $e');
    } finally {
      isLoadingPlayers.value = false;
    }
  }

  void onBannerTap(int index) {
    // Handle banner tap based on index
    switch (index) {
      case 0:
        Get.toNamed(RoutesName.bookACourt);
        break;
      case 1:
        Get.toNamed(RoutesName.bookACourt);
        break;
      case 2:
        Get.toNamed(RoutesName.bookACourt);
        break;
      case 3:
        Get.toNamed(RoutesName.bookACourt);
        break;
    }
  }
}