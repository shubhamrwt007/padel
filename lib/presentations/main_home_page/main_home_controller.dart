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

  final List<String> bannerImages = [
    Assets.imagesNewHomeBanner,
    Assets.imagesNewHomeBanner2,
    Assets.imagesNewHomeBanner4,
    Assets.imagesNewHomeBanner5,
  ];

  @override
  void onInit() async {
    super.onInit();
    pageController = PageController();
    await fetchCategories();
    
    // Fetch bookings with dynamic location from profile
    final locationId = profileController.profileModel.value?.response?.city?.sId ?? "68c94a94d72a6f9769712ff0";
    homeController.fetchBookings(
      categoryId: selectedCategoryId.value,
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
      final nextIndex = (currentBannerIndex.value + 1) % bannerImages.length;
      pageController.animateToPage(
        nextIndex,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  /// Handle sport tab changes
  void onSportTabChanged(int index) async {
    selectedSportTab.value = index;
    
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
      
      final response = await _openMatchRepository.getOpenMatchBookings(
        userid: userId,
        filter: 'allMatches',
        type: selectedCategoryId.value,
        matchDate: formattedDate,
      );
      
      openMatches.value = response;
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
        Get.toNamed(RoutesName.home);
        break;
      case 1:
        Get.toNamed(RoutesName.home);
        break;
      case 2:
        Get.toNamed(RoutesName.home);
        break;
      case 3:
        Get.toNamed(RoutesName.home);
        break;
    }
  }
}