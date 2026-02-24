import 'dart:async';
import 'package:flutter/material.dart';
import 'package:padel_mobile/presentations/auth/forgot_password/widgets/forgot_password_exports.dart';

class TournamentsController extends GetxController{
  var selectedTab = 0.obs;
  var currentLiveIndex = 0.obs;
  late PageController pageController;
  Timer? autoScrollTimer;
  final int totalPages = 3;
  final int initialPage = 10000;

  @override
  void onInit() {
    super.onInit();
    pageController = PageController(initialPage: initialPage);
    currentLiveIndex.value = initialPage % totalPages;
    startAutoScroll();
  }

  void startAutoScroll() {
    autoScrollTimer = Timer.periodic(Duration(seconds: 4), (timer) {
      if (pageController.hasClients) {
        pageController.nextPage(
          duration: Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void changeTab(int index) => selectedTab.value = index;
  void changeLiveIndex(int index) => currentLiveIndex.value = index % totalPages;

  @override
  void onClose() {
    autoScrollTimer?.cancel();
    pageController.dispose();
    super.onClose();
  }
}