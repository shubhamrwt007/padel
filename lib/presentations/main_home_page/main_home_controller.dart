import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';
import 'package:padel_mobile/core/network/dio_client.dart';
import 'package:padel_mobile/presentations/profile/profile_controller.dart';
import 'package:padel_mobile/presentations/home/home_controller.dart';
import 'package:padel_mobile/repositories/home_repository/home_repository.dart';
import 'package:padel_mobile/data/response_models/home_models/get_near_city_players_model.dart';
import 'package:padel_mobile/generated/assets.dart';
class MainHomeController extends GetxController{
  final ProfileController profileController = Get.put(ProfileController());
  final HomeController homeController = Get.put(HomeController());
  final HomeRepository _homeRepository = HomeRepository();

  final Rx<GetNearCityPlayers?> nearCityPlayers = Rx<GetNearCityPlayers?>(null);
  final RxBool isLoadingPlayers = false.obs;

  // Sport Tab Selection
  final RxInt selectedSportTab = 0.obs; // 0 = Padel, 1 = Pickleball

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
    homeController.fetchBookings();
    await fetchNearCityPlayers();
    await fetCustomerLeaderBoardRank();
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
  void onSportTabChanged(int index) {
    selectedSportTab.value = index;

    if (index == 0) {
      // Padel selected
      print('Padel sport selected');
      // You can add logic here to filter/load Padel-specific data
      // For example: homeController.fetchPadelCourts();
    } else {
      // Pickleball selected
      print('Pickleball sport selected');
      // You can add logic here to filter/load Pickleball-specific data
      // For example: homeController.fetchPickleballCourts();
      // Or show a "Coming Soon" message
      Get.snackbar(
        'Coming Soon',
        'Pickleball courts will be available soon!',
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 2),
      );
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