import 'package:flutter/cupertino.dart';
import 'package:padel_mobile/presentations/bookinghistory/booking_history_controller.dart';
import 'package:padel_mobile/presentations/bookinghistory/booking_history_screen.dart';
import 'package:padel_mobile/presentations/home/home_screen.dart';
import 'package:padel_mobile/presentations/leaderBoard/leader_board_controller.dart';
import 'package:padel_mobile/presentations/leaderBoard/leader_board_screen.dart';
import 'package:padel_mobile/presentations/main_home_page/main_home_controller.dart';
import 'package:padel_mobile/presentations/main_home_page/main_home_screen.dart';
import 'package:padel_mobile/presentations/openmatchbooking/openmatch_booking_controller.dart';
import 'package:padel_mobile/presentations/openmatchbooking/openmatch_booking_screen.dart';
import 'package:padel_mobile/presentations/profile/edit_profile/edit_profile_controller.dart';
import 'package:padel_mobile/presentations/profile/edit_profile/edit_profile_screen.dart';
import '../auth/forgot_password/widgets/forgot_password_exports.dart';
import '../home/home_controller.dart';

class BottomNavigationController extends GetxController {
  // HomeController homeController = Get.put(HomeController());
  MainHomeController mainHomeController = Get.put(MainHomeController());
  BookingHistoryController bookingHistoryController= Get.put(BookingHistoryController());
  // OpenMatchBookingController openMatchBookingController= Get.put(OpenMatchBookingController());
  // EditProfileController editProfileController = Get.put(EditProfileController());
  HomeController homeController = Get.put(HomeController());
  LeaderboardController leaderboardController = Get.put(LeaderboardController());
  final List<Map<String, dynamic>> tabs = [
    {'icon': Assets.images.icHomeBottomBar.path, 'label': 'Home','isSvg': true, 'size': 22.0},
    {'icon': Assets.images.icBookings.path, 'label': 'Bookings','isSvg': true, 'size': 26.0},
    {'icon':  Icons.bar_chart, 'label': 'LeaderBoard', 'isSvg': false, 'size': 28.0},
    {'icon': Assets.images.icBookACourtNew.path, 'label': 'Courts', 'isSvg': true, 'size': 28.0},

  ];


  // Reactive variable to hold selected index
  final selectedIndex = 0.obs;

  // List of pages (you can expand this as needed)
  final List<Widget> pages = [
    // HomeScreen(),
    MainHomeScreen(),
    BookingHistoryUi(),
    // OpenMatchBookingScreen(),
    LeaderboardScreen(),
    HomeScreen()
    // EditProfileUi()
    // SizedBox(
    //   height: Get.height,
    //   width: Get.width,
    //   child: Center(child: Text("Coming Soon",style: TextStyle(fontSize: 15),)),
    // ),
  ];

  // Function to update selected index
  void updateIndex(int index) {
    selectedIndex.value = index;
    
    // Refresh APIs when user comes back to home tab (index 0)
    if (index == 0) {
      _refreshHomeApis();
    }
  }

  Future<void> _refreshHomeApis() async {
    await Future.wait([
      mainHomeController.fetchPollResults(),
      mainHomeController.fetchScheduleMatches(),
      mainHomeController.fetchActiveLeagues(),
      mainHomeController.fetchActiveAmericanos(),
    ]);
  }

  // Get current page based on selected index
  Widget getCurrentPage() {
    return pages[selectedIndex.value];
  }
}