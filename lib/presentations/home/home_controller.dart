import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/components/loader_widgets.dart';
import 'package:padel_mobile/configs/components/snack_bars.dart';
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
  Future<void> fetchClubs({bool isRefresh = false}) async {
    try {
      log("Fetching clubs - Page: ${currentPage.value}, Search: ${searchQuery
          .value}");

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
      await fetchClubs();
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
    fetchClubs(isRefresh: true);
  }

  /// Retry fetching data
  Future<void> retryFetch() async {
    clubError.value = '';
    currentPage.value = 1;
    hasMoreData.value = true;
    isInitialized.value = false;

    await Future.wait([
      fetchClubs(isRefresh: true),
      fetchBookings(),
    ]);
  }

  /// Clear search and reset data
  void clearSearch() {
    searchQuery.value = '';
    currentPage.value = 1;
    hasMoreData.value = true;
    fetchClubs(isRefresh: true);
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

  /// Public method to check if booking is ongoing (accessible from UI)
  bool isBookingOngoing(BookingHistoryData booking) {
    return _isBookingOngoing(booking);
  }

  Future<void> fetchBookings() async {
    isLoadingBookings.value = true;
    try {
      final response = await bookingHistoryRepository.getBookingHistory(
          type: "upcoming");

      if (response.success == true && response.data != null) {
        // Sort bookings: ongoing bookings first, then by date/time
        final sortedBookings = List<BookingHistoryData>.from(response.data!);
        sortedBookings.sort((a, b) {
          final aIsOngoing = _isBookingOngoing(a);
          final bIsOngoing = _isBookingOngoing(b);

          // Ongoing bookings come first
          if (aIsOngoing && !bIsOngoing) return -1;
          if (!aIsOngoing && bIsOngoing) return 1;

          // For non-ongoing bookings, sort by date/time
          try {
            final aDate = DateTime.parse(a.bookingDate ?? '');
            final bDate = DateTime.parse(b.bookingDate ?? '');
            return aDate.compareTo(bDate);
          } catch (e) {
            return 0;
          }
        });

        // Assign sorted data back to response
        response.data = sortedBookings;
      }

      bookings.value = response;

      if (response.success == true) {
        final bookingWithOpenMatch = response.data
            ?.where((e) => e.openMatchId?.sId?.isNotEmpty == true)
            .toList();

        openMatchId.value =
        bookingWithOpenMatch != null && bookingWithOpenMatch.isNotEmpty
            ? bookingWithOpenMatch.first.openMatchId!.sId!
            : "";

        // Store scoreboard IDs and booking mappings
        scoreboardIds.clear();
        openMatchToBookingMap.clear();
        response.data?.forEach((booking) {
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
        });

        CustomLogger.logMessage(msg: "Booking fetched and sorted", level: LogLevel.debug);
      }
    } catch (e) {
      CustomLogger.logMessage(msg: e, level: LogLevel.error);
    } finally {
      isLoadingBookings.value = false;
    }
  }

  // Helper method to check if booking is ongoing
  bool _isBookingOngoing(BookingHistoryData booking) {
    try {
      if (booking.bookingDate == null ||
          booking.slot == null ||
          booking.slot!.isEmpty) {
        return false;
      }

      final bookingDate = DateTime.parse(booking.bookingDate!);
      final now = DateTime.now();

      // Check if booking is today
      if (bookingDate.year != now.year ||
          bookingDate.month != now.month ||
          bookingDate.day != now.day) {
        return false;
      }

      // Get slot times
      final slotTimes = booking.slot![0].slotTimes;
      if (slotTimes == null || slotTimes.isEmpty) {
        return false;
      }

      // Parse start and end times
      final startTime = _parseTimeString(slotTimes.first.time);
      final endTime = slotTimes.length > 1
          ? _parseTimeString(slotTimes.last.time)
          : startTime?.add(Duration(minutes: booking.duration ?? 60));

      if (startTime == null || endTime == null) {
        return false;
      }

      // Check if current time is between start and end
      final currentTime =
      DateTime(now.year, now.month, now.day, now.hour, now.minute);
      return currentTime.isAfter(startTime) && currentTime.isBefore(endTime);
    } catch (e) {
      log("Error checking ongoing booking: $e");
      return false;
    }
  }

  DateTime? _parseTimeString(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;

    try {
      // Handle format like "09:00 AM" or "21:00"
      final now = DateTime.now();

      if (timeStr.contains('AM') || timeStr.contains('PM')) {
        final format = DateFormat('hh:mm a');
        final time = format.parse(timeStr);
        return DateTime(now.year, now.month, now.day, time.hour, time.minute);
      } else {
        final parts = timeStr.split(':');
        if (parts.length == 2) {
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          return DateTime(now.year, now.month, now.day, hour, minute);
        }
      }
    } catch (e) {
      log("Error parsing time: $e");
    }

    return null;
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

  @override
  void onInit() {
    super.onInit();
    // notificationService.initialize();
    // var token = notificationService.getToken();
    // log("Firebase Token $token");

    // Initialize scroll controller listener for pagination
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        loadMore();
      }
    });

    // Fetch initial data
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.wait([
        fetchClubs(isRefresh: true),
        fetchBookings(),
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
  RxString loadingBookingId = ''.obs;
  Future<void> createScoreBoard({required String bookingId}) async {
    try {
      isCheckingScoreboard.value = true;
      loadingBookingId.value = bookingId;

      // Check if scoreboard already exists in fetched bookings
      final scoreboardId = scoreboardIds[bookingId];

      if (scoreboardId != null && scoreboardId.isNotEmpty) {
        // Scoreboard exists, push open match into scoreboard
        await repository.pushOpenMatchIntoScoreboard(
          body: {
            "scoreboardId": scoreboardId,
            "openMatchId": bookingId,
          },
        );
        isCheckingScoreboard.value = false;
        // Use actual bookingId for navigation
        final actualBookingId = openMatchToBookingMap[bookingId] ?? bookingId;
        Get.toNamed(RoutesName.scoreBoard, arguments: {"bookingId": actualBookingId});
        return;
      }

      // --- Create scoreboard ---
      final bookingList = bookings.value?.data ?? [];

      if (bookingList.isEmpty) {
        isCheckingScoreboard.value = false;
        SnackBarUtils.showInfoSnackBar("No booking data found");
        return;
      }

      final booking = bookingList.first;

      final body = {
        "bookingId": bookingId,
        "matchDate": booking.bookingDate ?? "",
        "matchTime": booking.slot?[0].slotTimes?[0].time ?? "",
        "userId": storage.read("userId") ?? "",
        "courtName": booking.slot?[0].courtName ?? "",
        "clubName": booking.registerClubId?.clubName ?? "",
        "matchType":booking.matchType??"",
        if (booking.bookingType != "normal" && openMatchId.value.isNotEmpty) "openMatchId": openMatchId.value,
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

      final response = await repository.createScoreBoard(data: body);

      isCheckingScoreboard.value = false;

      if (response.success == true) {
        Get.toNamed(RoutesName.scoreBoard, arguments: {"bookingId": bookingId});
      }
    } catch (e) {
      isCheckingScoreboard.value = false;
      SnackBarUtils.showErrorSnackBar("Failed to load or create scoreboard");
    }finally{
      loadingBookingId.value = '';
    }
  }
}