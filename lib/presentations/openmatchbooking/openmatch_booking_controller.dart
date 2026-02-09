import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/configs/components/snack_bars.dart';
import '../../data/response_models/openmatch_model/open_match_booking_model.dart';
import '../../handler/logger.dart';
import '../../repositories/openmatches/open_match_repository.dart';

class OpenMatchBookingController extends GetxController
    with GetSingleTickerProviderStateMixin {
  // TabController - not reactive since TabBar needs non-null controller
  TabController? _tabController;
  TabController? get tabController => _tabController;
  RxBool isControllerReady = false.obs;

  // Reactive variables
  RxString selectedSlot = 'Morning'.obs;
  RxBool showFilter = false.obs;

  final List<String> slots = ['Morning', 'Afternoon', 'Evening'];
  final List<String> categories = ['Level A', 'Level B', 'Level C'];

  final RxString selectedCategory = 'Select Category'.obs;
  final RxString selectedLevel = ''.obs;
  final RxList<String> selectedTimings = <String>[].obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;

  final GlobalKey dropdownKey = GlobalKey();

  // Separate lists for upcoming and completed matches
  RxList<OpenMatchBookingData> upcomingMatchesList = <OpenMatchBookingData>[].obs;
  RxList<OpenMatchBookingData> completedMatchesList = <OpenMatchBookingData>[].obs;

  // Loading states for each tab
  RxBool isLoadingUpcoming = false.obs;
  RxBool isLoadingCompleted = false.obs;
  RxBool isLoadingMoreUpcoming = false.obs;
  RxBool isLoadingMoreCompleted = false.obs;
  RxBool showNoInternetScreen = false.obs;

  // Separate pagination for each tab
  RxInt upcomingCurrentPage = 1.obs;
  RxInt completedCurrentPage = 1.obs;
  RxBool upcomingHasMoreData = true.obs;
  RxBool completedHasMoreData = true.obs;
  final int pageSize = 10;

  // Misc
  final OpenMatchRepository repository = Get.put(OpenMatchRepository());
  RxString argument = "".obs;
  RxString categoryId = ''.obs;
  RxString locationId = ''.obs;

  // Join requests
  RxList<Map<String, dynamic>> joinRequests = <Map<String, dynamic>>[].obs;
  RxBool isLoadingRequests = false.obs;
  RxString acceptingRequestId = ''.obs;
  RxString rejectingRequestId = ''.obs;

  // Helper getters for current tab with null safety
  RxList<OpenMatchBookingData> get currentList {
    if (_tabController == null) return upcomingMatchesList;
    return _tabController!.index == 0 ? upcomingMatchesList : completedMatchesList;
  }

  RxBool get isLoading {
    if (_tabController == null) return isLoadingUpcoming;
    return _tabController!.index == 0 ? isLoadingUpcoming : isLoadingCompleted;
  }

  RxBool get isLoadingMore {
    if (_tabController == null) return isLoadingMoreUpcoming;
    return _tabController!.index == 0 ? isLoadingMoreUpcoming : isLoadingMoreCompleted;
  }

  RxBool get hasMoreData {
    if (_tabController == null) return upcomingHasMoreData;
    return _tabController!.index == 0 ? upcomingHasMoreData : completedHasMoreData;
  }

  RxInt get currentPage {
    if (_tabController == null) return upcomingCurrentPage;
    return _tabController!.index == 0 ? upcomingCurrentPage : completedCurrentPage;
  }

  @override
  void onInit() {
    super.onInit();

    // Handle arguments safely
    final args = Get.arguments;
    if (args is Map) {
      if (args.containsKey("type")) {
        argument.value = args["type"];
      }
      if (args.containsKey("categoryId")) {
        categoryId.value = args["categoryId"];
      }
      if (args.containsKey("locationId")) {
        locationId.value = args["locationId"];
      }
    } else {
      argument.value = "upcoming";
    }

    // Initialize TabController with delay to ensure proper widget mounting
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tabController = TabController(length: 2, vsync: this);
      _tabController!.addListener(_handleTabChange);
      isControllerReady.value = true;

      // Initial data load for upcoming
      fetchOpenMatchesBooking(type: 'upcoming');
    });
  }

  void _handleTabChange() {
    // When tab index changes (and animation finishes)
    if (_tabController != null && !_tabController!.indexIsChanging) {
      String type = _tabController!.index == 0 ? 'upcoming' : 'completed';

      CustomLogger.logMessage(
        msg: "Tab changed to: $type",
        level: LogLevel.debug,
      );

      // Only fetch if the list is empty (first time loading this tab)
      if (type == 'upcoming' && upcomingMatchesList.isEmpty) {
        fetchOpenMatchesBooking(type: 'upcoming');
      } else if (type == 'completed' && completedMatchesList.isEmpty) {
        fetchOpenMatchesBooking(type: 'completed');
      }
    }
  }

  // Reset pagination for specific type
  void resetPagination({String? type}) {
    type ??= _tabController?.index == 0 ? 'upcoming' : 'completed';

    if (type == 'upcoming') {
      upcomingCurrentPage.value = 1;
      upcomingHasMoreData.value = true;
      upcomingMatchesList.clear();
    } else {
      completedCurrentPage.value = 1;
      completedHasMoreData.value = true;
      completedMatchesList.clear();
    }

    CustomLogger.logMessage(
      msg: "Pagination reset for $type",
      level: LogLevel.debug,
    );
  }

  void selectSlot(String slot) => selectedSlot.value = slot;

  Future<void> selectDate(BuildContext context) async {
    DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: now,
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          textTheme: const TextTheme(
            titleLarge: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            bodyLarge: TextStyle(fontSize: 14),
            bodyMedium: TextStyle(fontSize: 12),
          ),
        ),
        child: child!,
      ),
    );

    if (pickedDate != null) {
      selectedDate.value = pickedDate;
      CustomLogger.logMessage(
        msg: "Date selected: $pickedDate",
        level: LogLevel.debug,
      );
    }
  }

  void clearAll() {
    selectedDate.value = DateTime.now();
    selectedTimings.clear();
    selectedLevel.value = '';
    CustomLogger.logMessage(
      msg: "Filters cleared",
      level: LogLevel.debug,
    );
  }

  Future<void> fetchOpenMatchesBooking({
    required String type,
    bool isLoadMore = false,
  }) async {
    try {
      // Set loading state based on type
      if (type == 'upcoming') {
        if (isLoadMore) {
          isLoadingMoreUpcoming.value = true;
        } else {
          isLoadingUpcoming.value = true;
        }
      } else {
        if (isLoadMore) {
          isLoadingMoreCompleted.value = true;
        } else {
          isLoadingCompleted.value = true;
        }
      }

      final page = type == 'upcoming' ? upcomingCurrentPage.value : completedCurrentPage.value;

      CustomLogger.logMessage(
        msg: "Fetching $type matches - Page: $page, IsLoadMore: $isLoadMore",
        level: LogLevel.info,
      );

      final response = await repository.getOpenMatchBookings(
        type: type,
        page: page,
        limit: pageSize,
        categoryId: categoryId.value.isNotEmpty ? categoryId.value : null,
        locationId: locationId.value.isNotEmpty ? locationId.value : null,
      );

      if (response != null && response.data != null && response.data!.isNotEmpty) {
        final newData = response.data!;

        if (type == 'upcoming') {
          if (isLoadMore) {
            upcomingMatchesList.addAll(newData);
          } else {
            upcomingMatchesList.value = newData;
          }
          upcomingHasMoreData.value = newData.length >= pageSize;
        } else {
          if (isLoadMore) {
            completedMatchesList.addAll(newData);
          } else {
            completedMatchesList.value = newData;
          }
          completedHasMoreData.value = newData.length >= pageSize;
        }

        CustomLogger.logMessage(
          msg: "Successfully fetched ${newData.length} $type matches. Total: ${type == 'upcoming' ? upcomingMatchesList.length : completedMatchesList.length}",
          level: LogLevel.info,
        );
      } else {
        if (!isLoadMore) {
          if (type == 'upcoming') {
            upcomingMatchesList.clear();
            upcomingHasMoreData.value = false;
          } else {
            completedMatchesList.clear();
            completedHasMoreData.value = false;
          }
        } else {
          if (type == 'upcoming') {
            upcomingHasMoreData.value = false;
          } else {
            completedHasMoreData.value = false;
          }
        }

        CustomLogger.logMessage(
          msg: "No matches found for $type",
          level: LogLevel.info,
        );
      }
    } catch (e) {
      CustomLogger.logMessage(
        msg: "Error fetching $type matches: $e",
        level: LogLevel.error,
      );

      if (!isLoadMore) {
        if (type == 'upcoming') {
          upcomingMatchesList.clear();
          upcomingHasMoreData.value = false;
        } else {
          completedMatchesList.clear();
          completedHasMoreData.value = false;
        }
      }
    } finally {
      if (type == 'upcoming') {
        isLoadingUpcoming.value = false;
        isLoadingMoreUpcoming.value = false;
      } else {
        isLoadingCompleted.value = false;
        isLoadingMoreCompleted.value = false;
      }
    }
  }

  Future<void> loadMoreData({String? type}) async {
    type ??= _tabController?.index == 0 ? 'upcoming' : 'completed';
    final hasMore = type == 'upcoming' ? upcomingHasMoreData.value : completedHasMoreData.value;
    final isLoadingMore = type == 'upcoming' ? isLoadingMoreUpcoming.value : isLoadingMoreCompleted.value;

    if (!hasMore || isLoadingMore) return;

    // Increment page number
    if (type == 'upcoming') {
      upcomingCurrentPage.value++;
    } else {
      completedCurrentPage.value++;
    }

    await fetchOpenMatchesBooking(type: type, isLoadMore: true);
  }

  Future<void> fetchJoinRequests(String matchId) async {
    try {
      isLoadingRequests.value = true;

      final response = await repository.getRequestPlayersOpenMatch(matchId: matchId,type: "MatchCreator");

      if (response != null && response.requests != null) {
        joinRequests.value = response.requests!.map((request) => {
          'id': request.id ?? '',
          'name': request.requester?.name ?? 'Unknown',
          'profilePic': request.requester?.profilePic?? '',
          // 'level': request.level ?? '',
          'lastName': request.requester?.lastName ?? '',
          'requestedAt': request.createdAt ?? DateTime.now(),
        }).toList();
      } else {
        joinRequests.clear();
      }
    } catch (e) {
      CustomLogger.logMessage(
        msg: "Error fetching join requests: $e",
        level: LogLevel.error,
      );
      joinRequests.clear();
    } finally {
      isLoadingRequests.value = false;
    }
  }

  Future<void> acceptRequest(String requestId, String matchId) async {
    try {
      acceptingRequestId.value = requestId;
      final body = {
        "requestId": requestId,
        "action": "accept"
      };
      
      final response = await repository.acceptOrRejectRequestPlayer(body: body);
      joinRequests.removeWhere((req) => req['id'] == requestId);
      // SnackBarUtils.showSuccessSnackBar(response?.message ?? "Request accepted");
      fetchOpenMatchesBooking(type: 'upcoming');
    } catch (e) {
      CustomLogger.logMessage(msg: "Error $e", level: LogLevel.error);
    } finally {
      acceptingRequestId.value = '';
    }
  }

  Future<void> rejectRequest(String requestId, String matchId) async {
    try {
      rejectingRequestId.value = requestId;
      final body = {
        "requestId": requestId,
        "action": "reject"
      };
      
      final response = await repository.acceptOrRejectRequestPlayer(body: body);
      joinRequests.removeWhere((req) => req['id'] == requestId);
      // SnackBarUtils.showSuccessSnackBar(response?.message ?? "Request rejected");
      // fetchOpenMatchesBooking(type: 'upcoming');
    } catch (e) {
      CustomLogger.logMessage(msg: "Error $e", level: LogLevel.error);
    } finally {
      rejectingRequestId.value = '';
    }
  }

  @override
  void onClose() {
    _tabController?.dispose();
    super.onClose();
  }
}