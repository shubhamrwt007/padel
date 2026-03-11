import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LeagueController extends GetxController with GetSingleTickerProviderStateMixin {
  final RxInt selectedTab = 0.obs;
  final RxInt matchTab = 1.obs; // 0: Upcoming, 1: Live, 2: Results
  late PageController pageController;
  late TabController tabController;

  @override
  void onInit() {
    super.onInit();
    pageController = PageController(initialPage: 1);
    tabController = TabController(length: 3, vsync: this, initialIndex: 1);
  }

  @override
  void onClose() {
    pageController.dispose();
    tabController.dispose();
    super.onClose();
  }

  void onTabChanged(int index) {
    matchTab.value = index;
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void onPageChanged(int index) {
    matchTab.value = index;
    tabController.animateTo(index);
  }
}