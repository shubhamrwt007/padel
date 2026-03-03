import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/components/loader_widgets.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';
import 'package:padel_mobile/core/network/dio_client.dart';
import 'package:padel_mobile/data/request_models/booking/boking_history_model.dart';
import 'package:padel_mobile/handler/logger.dart';
import 'package:padel_mobile/presentations/profile/profile_controller.dart';
import 'package:padel_mobile/repositories/bookinghisory/booking_history_repository.dart';
import 'package:padel_mobile/repositories/score_board_repo/score_board_repository.dart';
import '../../data/request_models/home_models/get_club_name_model.dart';
import '../../repositories/home_repository/home_repository.dart';
import '../../repositories/authentication_repository/sign_up_repository.dart';
import '../main_home_page/main_home_controller.dart';

class HomeController extends GetxController {

  ProfileController profileController = Get.put(ProfileController());

  // LOCATION ------------------------------------------------------------------
  final RxString selectedLocation = ''.obs;
  RxBool showLocationAndDate = false.obs;
  ScrollController scrollController = ScrollController();
  final SignUpRepository signUpRepository = SignUpRepository();
  final RxList<String> locations = <String>[].obs;
  RxBool isLoadingLocations = false.obs;

  // DATE -------------------------
  var selectedDate = DateTime
      .now()
      .obs;

  Future<void> selectDate(BuildContext context) async {
    try {
      DateTime now = DateTime.now();
      DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: selectedDate.value,
        firstDate: now,
        lastDate: DateTime(2100),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              textTheme: const TextTheme(
                titleLarge: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                bodyLarge: TextStyle(fontSize: 14),
                bodyMedium: TextStyle(fontSize: 12),
              ),
            ),
            child: child!,
          );
        },
      );
      if (pickedDate != null) {
        selectedDate.value = pickedDate;
      }
    } catch (e) {
      log("Error selecting date: $e");
      // Handle date selection error gracefully
    }
  }

  // CLUB DATA -----------------------------------------------------------------
  final HomeRepository clubRepository = HomeRepository();

  // Using nullable type for proper null handling
  Rx<CourtsModel?> courtsData = Rx<CourtsModel?>(null);
  RxBool isLoadingClub = false.obs;
  RxBool isLoadingMore = false.obs;
  RxString clubError = ''.obs;
  RxInt currentPage = 1.obs;
  final int limit = 20;
  RxString searchQuery = ''.obs;
  RxBool hasMoreData = true.obs;
  RxBool isInitialized = false.obs;
  RxInt totalCourts = 0.obs;

  // State getters for better state management
  bool get isInitialLoading {
    return isLoadingClub.value && !isInitialized.value;
  }

  bool get hasErrorWithNoData {
    return clubError.value.isNotEmpty && !hasCourtsData;
  }

  bool get shouldShowEmptyState {
    return !hasCourtsData &&
        isInitialized.value &&
        !isLoadingClub.value &&
        clubError.value.isEmpty;
  }

  // Check if courts data is available
  bool get hasCourtsData {
    return courtsData.value != null &&
        courtsData.value!.data != null &&
        courtsData.value!.data!.courts != null &&
        courtsData.value!.data!.courts!.isNotEmpty;
  }

  /// Get courts list safely
  List<dynamic> get courtsList {
    if (hasCourtsData) {
      return courtsData.value!.data!.courts!;
    }
    return [];
  }

  /// Get courts count safely
  int get courtsCount {
    return courtsList.length;
  }

  /// Fetch clubs with pagination and comprehensive error handling
  Future<void> fetchClubs({bool isRefresh = false, String? categoryId, String? locationId}) async {
    try {
      if (isRefresh) {
        currentPage.value = 1;
      }
      
      log("Fetching clubs - Page: ${currentPage.value}, Search: ${searchQuery.value}, CategoryId: $categoryId, LocationId: $locationId");

      if (isRefresh || currentPage.value == 1) {
        isLoadingClub.value = true;
        clubError.value = '';
        hasMoreData.value = true;
      } else {
        isLoadingMore.value = true;
      }

      // Make API call
      final result = await clubRepository.fetchClubData(
        limit: limit.toString(),
        page: currentPage.value.toString(),
        search: searchQuery.value,
        categoryId: categoryId,
        locationId: locationId,
      );

      log("Courts length ${result.data?.courts?.length ?? 0}");

      // Handle successful response
      if (result.data?.courts != null) {
        if (isRefresh || currentPage.value == 1) {
          courtsData.value = result;
        } else {
          // Merge new data with existing data
          if (courtsData.value?.data?.courts != null) {
            final existingCourts = courtsData.value!.data!.courts!;
            final newCourts = result.data!.courts!;

            existingCourts.addAll(newCourts);

            // Check if more data is available
            hasMoreData.value = newCourts.length >= limit;
          }
        }

        // Update total count
        totalCourts.value = courtsData.value?.data?.courts?.length ?? 0;

        // Clear any existing errors
        clubError.value = '';
      }

      // Mark as initialized after first successful fetch
      if (!isInitialized.value) {
        isInitialized.value = true;
      }

      log("Successfully fetched ${courtsData.value?.data?.courts?.length ??
          0} courts");
    } catch (e) {
      log("Error fetching clubs: $e");

      // Set appropriate error message
      if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        clubError.value =
        'Network error. Please check your connection and try again.';
      } else if (e.toString().contains('timeout')) {
        clubError.value = 'Request timeout. Please try again.';
      } else if (e.toString().contains('server')) {
        clubError.value = 'Server error. Please try again later.';
      } else {
        clubError.value = 'Failed to load courts. Please try again.';
      }

      // Only mark as initialized if this was the first attempt
      if (!isInitialized.value && (isRefresh || currentPage.value == 1)) {
        isInitialized.value = true;
      }
    } finally {
      // Reset loading states
      isLoadingClub.value = false;
      isLoadingMore.value = false;
    }
  }
  /// Load more data for pagination with better error handling
  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMoreData.value || !isInitialized.value) {
      return;
    }

    try {
      currentPage.value++;
      
      // Get categoryId and locationId from MainHomeController if available
      try {
        final mainHomeController = Get.find<MainHomeController>();
        final categoryId = mainHomeController.selectedCategoryId.value;
        final locationId = mainHomeController.profileController.profileModel.value?.response?.city?.sId ?? "68c94a94d72a6f9769712ff0";
        await fetchClubs(categoryId: categoryId, locationId: locationId);
      } catch (e) {
        await fetchClubs();
      }
    } catch (e) {
      // Revert page increment on error
      currentPage.value = (currentPage.value - 1).clamp(1, currentPage.value);
      log("Error loading more: $e");
    }
  }

  /// Search clubs with debouncing
  void searchClubs(String query) {
    searchQuery.value = query.trim();
    currentPage.value = 1;
    hasMoreData.value = true;
    
    // Get categoryId and locationId from MainHomeController if available
    try {
      final mainHomeController = Get.find<MainHomeController>();
      final categoryId = mainHomeController.selectedCategoryId.value;
      final locationId = mainHomeController.profileController.profileModel.value?.response?.city?.sId ?? "68c94a94d72a6f9769712ff0";
      fetchClubs(isRefresh: true, categoryId: categoryId, locationId: locationId);
    } catch (e) {
      fetchClubs(isRefresh: true);
    }
  }

  /// Retry fetching data
  Future<void> retryFetch() async {
    clubError.value = '';
    currentPage.value = 1;
    hasMoreData.value = true;
    isInitialized.value = false;

    // Get categoryId and locationId from MainHomeController if available
    try {
      final mainHomeController = Get.find<MainHomeController>();
      final categoryId = mainHomeController.selectedCategoryId.value;
      final locationId = mainHomeController.profileController.profileModel.value?.response?.city?.sId ?? "68c94a94d72a6f9769712ff0";
      
      await Future.wait([
        fetchClubs(isRefresh: true, categoryId: categoryId, locationId: locationId),
        fetchBookings(categoryId: categoryId, locationId: locationId),
      ]);
    } catch (e) {
      // Fallback if MainHomeController not found
      await Future.wait([
        fetchClubs(isRefresh: true),
        fetchBookings(),
      ]);
    }
  }

  /// Clear search and reset data
  void clearSearch() {
    searchQuery.value = '';
    currentPage.value = 1;
    hasMoreData.value = true;
    
    // Get categoryId and locationId from MainHomeController if available
    try {
      final mainHomeController = Get.find<MainHomeController>();
      final categoryId = mainHomeController.selectedCategoryId.value;
      final locationId = mainHomeController.profileController.profileModel.value?.response?.city?.sId ?? "68c94a94d72a6f9769712ff0";
      fetchClubs(isRefresh: true, categoryId: categoryId, locationId: locationId);
    } catch (e) {
      fetchClubs(isRefresh: true);
    }
  }

  /// Update selected location
  void updateLocation(String location) {
    selectedLocation.value = location;
    // Optionally refresh data based on location
  }

  bool get isLoadingAll => isLoadingClub.value || isLoadingBookings.value;

  ///Your Bookings--------------------------------------------------------------
  var bookings = Rxn<BookingHistoryModel>();
  BookingHistoryRepository bookingHistoryRepository = Get.put(
      BookingHistoryRepository());
  RxBool isLoadingBookings = false.obs;

  final openMatchId = "".obs;
  final RxMap<String, String> scoreboardIds = <String, String>{}.obs;
  final RxMap<String, String> openMatchToBookingMap = <String, String>{}.obs;
  final RxSet<String> inProgressBookingIds = <String>{}.obs;

  /// Public method to check if booking is ongoing (accessible from UI)
  bool isBookingOngoing(BookingHistoryData booking) {
    return inProgressBookingIds.contains(booking.sId);
  }

  Future<void> fetchBookings({String? categoryId, String? locationId}) async {
    isLoadingBookings.value = true;
    try {
      // Verify we have the correct userId and token
      final currentUserId = storage.read('userId');
      final currentToken = storage.read('token');
      log("🔐 Fetching bookings for userId: $currentUserId");
      log("🔐 Token exists: ${currentToken != null && currentToken.isNotEmpty}");
      log("📋 Fetching bookings with categoryId: $categoryId, locationId: $locationId");

      final ongoingResponse = await bookingHistoryRepository.getBookingHistory(
        type: "in-progress",
        categoryId: categoryId,
        locationId: locationId,
      );
      final upcomingResponse = await bookingHistoryRepository.getBookingHistory(
        type: "upcoming",
        categoryId: categoryId,
        locationId: locationId,
      );

      final allBookings = <BookingHistoryData>[];
      inProgressBookingIds.clear();

      if (ongoingResponse.success == true && ongoingResponse.data != null) {
        allBookings.addAll(ongoingResponse.data!);
        for (var booking in ongoingResponse.data!) {
          if (booking.sId != null) {
            inProgressBookingIds.add(booking.sId!);
          }
        }
      }

      if (upcomingResponse.success == true && upcomingResponse.data != null) {
        allBookings.addAll(upcomingResponse.data!);
      }

      if (allBookings.isNotEmpty) {
        allBookings.sort((a, b) {
          final aIsOngoing = inProgressBookingIds.contains(a.sId);
          final bIsOngoing = inProgressBookingIds.contains(b.sId);

          if (aIsOngoing && !bIsOngoing) return -1;
          if (!aIsOngoing && bIsOngoing) return 1;

          try {
            final aDate = DateTime.parse(a.bookingDate ?? '');
            final bDate = DateTime.parse(b.bookingDate ?? '');
            return aDate.compareTo(bDate);
          } catch (e) {
            return 0;
          }
        });
      }

      bookings.value = BookingHistoryModel(
        success: true,
        data: allBookings,
      );

      if (allBookings.isNotEmpty) {
        final bookingWithOpenMatch = allBookings
            .where((e) => e.openMatchId?.sId?.isNotEmpty == true)
            .toList();

        openMatchId.value =
        bookingWithOpenMatch.isNotEmpty
            ? bookingWithOpenMatch.first.openMatchId!.sId!
            : "";

        scoreboardIds.clear();
        openMatchToBookingMap.clear();
        for (var booking in allBookings) {
          final actualBookingId = booking.sId;
          final openMatchIdValue = booking.openMatchId?.sId;

          if (booking.bookingType == "openMatch" && openMatchIdValue != null && actualBookingId != null) {
            openMatchToBookingMap[openMatchIdValue] = actualBookingId;
          }

          final bookingId = booking.bookingType == "openMatch"
              ? openMatchIdValue
              : actualBookingId;
          if (bookingId != null && booking.scoreboard?.sId != null) {
            scoreboardIds[bookingId] = booking.scoreboard!.sId!;
          }
        }

        CustomLogger.logMessage(msg: "Booking fetched and sorted", level: LogLevel.debug);
      }
    } catch (e) {
      CustomLogger.logMessage(msg: e, level: LogLevel.error);
    } finally {
      isLoadingBookings.value = false;
    }
  }




  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEE, dd MMM').format(date); // e.g., Thu, 27 June
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> fetchLocations() async {
    try {
      isLoadingLocations.value = true;
      final response = await signUpRepository.getLocations();
      if (response.status == true && response.data != null) {
        locations.value = response.data!.map((location) => location.name ?? '').where((name) => name.isNotEmpty).toList();
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "Error fetching locations: $e", level: LogLevel.error);
    } finally {
      isLoadingLocations.value = false;
    }
  }

  void showLocationPicker() async { // Context is no longer needed in arguments
    if (locations.isEmpty && !isLoadingLocations.value) {
      await fetchLocations();
    }
    final locationScrollController = ScrollController();
    // Get.dialog does not require a BuildContext
    final result = await Get.dialog<String>(
      AlertDialog(
        title: Text('Select Location', style: Get.textTheme.titleMedium!.copyWith(color: AppColors.primaryColor)),
        content: SizedBox(
          width: double.maxFinite,
          child: Obx(() {
            // Scroll after the first frame
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final index = locations.indexOf(selectedLocation.value);
              if (index != -1 && locationScrollController.hasClients) {
                locationScrollController.animateTo(
                  index * 35, // Approx height of each ListTile
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });

            return isLoadingLocations.value
                ? const Center(
              child: LoadingWidget(color: AppColors.primaryColor),
            )
                : ListView.builder(
              controller: locationScrollController,
              shrinkWrap: true,
              itemCount: locations.length,
              itemBuilder: (_, index) {
                final location = locations[index];
                final isSelected = selectedLocation.value == location;

                return ListTile(
                  dense: true,
                  tileColor: isSelected
                      ? AppColors.primaryColor.withValues(alpha: 0.1)
                      : null,
                  title: Text(
                    location,
                    style: TextStyle(
                      fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                      color:
                      isSelected ? AppColors.primaryColor : null,
                    ),
                  ),
                  onTap: () => Get.back(result: location),
                );
              },
            );
          }),
        ),
      ),
    );

    if (result != null) selectedLocation.value = result;
  }

  void clearAllData() {
    bookings.value = null;
    courtsData.value = null;
    isInitialized.value = false;
    currentPage.value = 1;
    hasMoreData.value = true;
    searchQuery.value = '';
    clubError.value = '';
    totalCourts.value = 0;
    scoreboardIds.clear();
    openMatchToBookingMap.clear();
    openMatchId.value = '';
    inProgressBookingIds.clear();
  }

  @override
  void onInit() async {
    super.onInit();

    clearAllData();

    // Initialize scroll controller listener for pagination
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        loadMore();
      }
    });

    // Fetch initial data - don't pass parameters here, let MainHomeController handle it
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.wait([
        fetchLocations(),
      ]);
    });
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  ScoreBoardRepository repository = Get.put(ScoreBoardRepository());
  RxBool isCheckingScoreboard = false.obs;
  RxBool isCreatingScoreboard = false.obs;
  RxString loadingBookingId = ''.obs;
  Future<void> createScoreBoard({required String bookingId}) async {
    try {
      isCheckingScoreboard.value = true;
      isCreatingScoreboard.value = true;
      loadingBookingId.value = bookingId;

      final bookingList = bookings.value?.data ?? [];
      if (bookingList.isEmpty) {
        isCheckingScoreboard.value = false;
        return;
      }

      final booking = bookingList.firstWhere(
            (b) => b.sId == bookingId || b.openMatchId?.sId == bookingId,
        orElse: () => bookingList.first,
      );

      final actualBookingId = booking.bookingType == "openMatch" ? booking.sId : bookingId;

      // ✅ SOLUTION: First check if scoreboard exists via API
      try {
        final scoreboardResponse = await repository.getScoreBoard(bookingId: actualBookingId ?? bookingId);

        if (scoreboardResponse.status == 200 &&
            scoreboardResponse.data != null &&
            scoreboardResponse.data!.isNotEmpty) {
          // Scoreboard already exists, just navigate
          isCheckingScoreboard.value = false;
          Get.toNamed(RoutesName.scoreBoard, arguments: {"bookingId": actualBookingId ?? bookingId});
          return;
        }
      } catch (e) {
        // Scoreboard doesn't exist, continue to create
        CustomLogger.logMessage(msg: "No existing scoreboard found: $e", level: LogLevel.info);
      }

      // Create new scoreboard only if none exists
      final body = {
        "bookingId": actualBookingId ?? bookingId,
        "matchDate": booking.bookingDate ?? "",
        "matchTime": booking.slot?[0].slotTimes?[0].time ?? "",
        "userId": storage.read("userId") ?? "",
        "courtName": booking.slot?[0].courtName ?? "",
        "clubName": booking.registerClubId?.clubName ?? "",
        "matchType": booking.matchType ?? "",
        "teams": [
          {
            "name": "Team A",
            "players": [
              {
                "name": "Team A",
                "playerId": storage.read("userId") ?? "",
              }
            ]
          }
        ]
      };

      log("💡 Create Score Board Body-> $body");

      final response = await repository.createScoreBoard(data: body);

      isCheckingScoreboard.value = false;
      isCreatingScoreboard.value = false;

      if (response.success == true) {
        Get.toNamed(RoutesName.scoreBoard, arguments: {"bookingId": actualBookingId ?? bookingId});
        await fetchBookings();
      }
    } catch (e) {
      isCheckingScoreboard.value = false;
      isCreatingScoreboard.value = false;
    } finally {
      loadingBookingId.value = '';
      isCreatingScoreboard.value = false;
    }
  }
}