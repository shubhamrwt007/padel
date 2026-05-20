import 'package:intl/intl.dart';
import '../../../data/request_models/home_models/get_club_name_model.dart';
import '../../../data/response_models/openmatch_model/open_match_model.dart';
import '../../../presentations/booking/widgets/booking_exports.dart';

class OpenMatchesController extends GetxController {
  Rx<bool> viewUnavailableSlots = false.obs;
  RxList<String> selectedSlots = <String>[].obs;
  RxString selectedTimeFilter = 'morning'.obs; // New: for tab selection
  RxString selectedGameLevel = 'Game Level'.obs; // New: for game level selection
  RxBool isGameLevelSelected = false.obs; // Track if game level is selected
  RxInt expandedIndex = (-1).obs; // Add expanded index for card expansion

  String? selectedTime;
  Rx<DateTime> selectedDate = DateTime.now().obs;
  RxBool isLoading = false.obs;
  Rx<OpenMatchModel?> createdMatch = Rx<OpenMatchModel?>(null);
  Rx<AllOpenMatches?> matchesBySelection = Rx<AllOpenMatches?>(null);
  RxString errorMessage = ''.obs;
  
  // Join requests related observables
  RxList<Map<String, dynamic>> joinRequests = <Map<String, dynamic>>[].obs;
  RxBool isLoadingRequests = false.obs;
  RxString acceptingRequestId = ''.obs;
  RxString rejectingRequestId = ''.obs;
  
  // Nearby players
  RxList<Map<String, dynamic>> nearbyPlayers = <Map<String, dynamic>>[].obs;
  RxBool isLoadingNearbyPlayers = false.obs;
  RxString requestingPlayerId = ''.obs; // Track which player request is in progress
  RxList<String> requestedPlayerIds = <String>[].obs; // Track requested players
  RxBool invitationSent = false.obs;
  RxBool isSendingInvitation = false.obs;
  
  // Pagination for nearby players
  RxInt currentPage = 1.obs;
  RxInt totalPages = 1.obs;
  RxBool hasMore = true.obs;
  RxBool isLoadingMore = false.obs;
  RxString currentBookingId = ''.obs;
  final ScrollController nearbyPlayersScrollController = ScrollController();

  final List<String> timeSlots = [
    "6:00 am",
    "7:00 am",
    "8:00 am",
    "9:00 am",
    "10:00 am",
    "11:00 am",
    "12:00 pm",
    "1:00 pm",
    "2:00 pm",
    "3:00 pm",
    "4:00 pm",
    "5:00 pm",
    "6:00 pm",
    "7:00 pm",
    "8:00 pm",
    "9:00 pm",
    "10:00 pm",
    "11:00 pm",
  ];

  String getDay(String? ymd) {
    if (ymd == null || ymd.isEmpty) return '';
    try {
      final parsed = DateFormat('yyyy-MM-dd').parse(ymd);
      return DateFormat('EEEE').format(parsed);
    } catch (_) {
      return ymd;
    }
  }

  String getDate(String? ymd) {
    if (ymd == null || ymd.isEmpty) return '';
    try {
      final parsed = DateFormat('yyyy-MM-dd').parse(ymd);
      return DateFormat('dd MMM').format(parsed);
    } catch (_) {
      return ymd;
    }
  }

  Courts argument = Courts();
  Rx<DateTime> focusedDate = DateTime.now().obs; // Add this new line

  var categoryId = "".obs;
  var locationID = "".obs;
  var locationsId = "".obs;
  var sId = "".obs;
  @override
  void onInit() {
    super.onInit();
    focusedDate.value = selectedDate.value; // Add this line
    argument = Get.arguments["data"];
    sId.value = Get.arguments['sID']??"";
    categoryId.value = Get.arguments['categoryId']??"";
    locationID.value = Get.arguments['location']??"";
    locationsId.value = Get.arguments['locationsId']??"";
    if (timeSlots.isNotEmpty) {
      final firstAvail = firstAvailableSlot();
      if (firstAvail != null) {
        selectedSlots
          ..clear()
          ..add(firstAvail);
        selectedTime = firstAvail;
      } else {
        selectedSlots.clear();
        selectedTime = null;
      }
      fetchMatchesForSelection();
    }
    
    // Setup scroll listener for pagination
    nearbyPlayersScrollController.addListener(_nearbyPlayersScrollListener);
  }

  void _nearbyPlayersScrollListener() {
    if (nearbyPlayersScrollController.position.pixels >= nearbyPlayersScrollController.position.maxScrollExtent - 200) {
      if (!isLoadingMore.value && hasMore.value) {
        loadMoreNearbyPlayers();
      }
    }
  }

  /// Get time period (morning, noon, evening) for a given time slot
  String getTimePeriod(String timeSlot) {
    try {
      final cleaned = timeSlot.replaceAll(' ', '').toUpperCase();
      DateTime? parsed;

      try {
        parsed = DateFormat('h:mma').parse(cleaned);
      } catch (_) {
        try {
          parsed = DateFormat('hha').parse(cleaned);
        } catch (_) {
          try {
            parsed = DateFormat('ha').parse(cleaned);
          } catch (_) {
            return 'morning';
          }
        }
      }

      final hour = parsed.hour;

      if (hour >= 6 && hour < 12) {
        return 'morning'; // 6 AM - 11:59 AM
      } else if (hour >= 12 && hour < 17) {
        return 'afternoon'; // 12 PM - 4:59 PM
      } else {
        return 'evening'; // 5 PM onwards
      }
    } catch (_) {
      return 'morning';
    }
  }

  /// Filter slots by selected time period
  List<String> filterSlotsByPeriod(List<String> slots) {
    final filter = selectedTimeFilter.value;
    if (filter == 'afternoon') {
      // Noon: 12 PM to 4 PM
      return slots.where((slot) => getTimePeriod(slot) == 'afternoon').toList();
    } else if (filter == 'evening') {
      // Evening: 5 PM to 11 PM
      return slots.where((slot) => getTimePeriod(slot) == 'evening').toList();
    }
    return slots.where((slot) => getTimePeriod(slot) == filter).toList();
  }

  /// Filtered available slots based on tab selection
  List<String> get filteredAvailableSlots {
    return filterSlotsByPeriod(availableSlots);
  }

  /// Filtered unavailable slots based on tab selection
  List<String> get filteredUnavailableSlots {
    return filterSlotsByPeriod(unavailableSlots);
  }
  final OpenMatchRepository repository = Get.put(OpenMatchRepository());
  /// Function to create match
  Future<void> createOpenMatch() async {
    try {
      isLoading.value = true;

      if (selectedTime == null) {
        CustomLogger.logMessage(msg: "Please select a time slot", level: LogLevel.error);
        return;
      }

      String formattedDate = DateFormat("yyyy-MM-dd").format(selectedDate.value);

      final data = {
        "matchDate": formattedDate,
        "matchTime": selectedTime,
        "slots": selectedSlots,
      };

      final response = await repository.createMatch(data: data);

      createdMatch.value = response;
      CustomLogger.logMessage(msg: "Match created successfully!", level: LogLevel.error);

    } catch (e) {
      CustomLogger.logMessage(msg: e, level: LogLevel.error);
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch matches for selected date and first chosen time slot
  Future<void> fetchMatchesForSelection() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      _ensureValidSelection();
      if (selectedTime == null) {
        matchesBySelection.value = null;
        return;
      }
      final formattedDate = DateFormat("yyyy-MM-dd").format(selectedDate.value);

      // final formattedTime = _formatTimeForApi(selectedTime!);

      final response = await repository.getMatchesByDateTime(
        matchDate: formattedDate,
        matchTime: '',
        cubId: argument.id ?? "",
        search: selectedGameLevel.value == 'Game Level' ? '' : selectedGameLevel.value,
        dayfilter: selectedTimeFilter.value,
      );
      matchesBySelection.value = response;
    } catch (e) {
      errorMessage.value = e.toString();
      CustomLogger.logMessage(msg: "Error -> ${errorMessage.value}", level: LogLevel.error);
    } finally {
      isLoading.value = false;
    }
  }

  String _formatTimeForApi(String raw) {
    final cleaned = raw.replaceAll(' ', '').toUpperCase();
    DateTime? parsed;
    try {
      parsed = DateFormat('h:mma').parse(cleaned);
    } catch (_) {
      try {
        parsed = DateFormat('hha').parse(cleaned);
      } catch (_) {
        try {
          parsed = DateFormat('ha').parse(cleaned);
        } catch (_) {
          parsed = null;
        }
      }
    }
    if (parsed == null) {
      return raw;
    }
    return DateFormat('h a').format(parsed).toLowerCase();
  }

  /// Format time range from list of times
  String formatTimeRange(List<String>? times) {
    if (times == null || times.isEmpty) return '';
    if (times.length == 1) return times.first;

    final first = times.first;
    final last = times.last;

    // Extract number from first time (e.g., "8" from "8 pm")
    final firstNumber = first.replaceAll(RegExp(r'[^0-9]'), '');

    return '$firstNumber-$last';
  }

  bool isPastTime(String slotLabel) {
    try {
      final targetDate = selectedDate.value;
      final now = DateTime.now();

      if (DateTime(targetDate.year, targetDate.month, targetDate.day)
          .isAfter(DateTime(now.year, now.month, now.day))) {
        return false;
      }

      if (DateTime(targetDate.year, targetDate.month, targetDate.day)
          .isBefore(DateTime(now.year, now.month, now.day))) {
        return true;
      }

      final cleaned = slotLabel.replaceAll(' ', '').toUpperCase();
      final parsed = DateFormat('ha').parse(cleaned);
      final slotDateTime = DateTime(targetDate.year, targetDate.month, targetDate.day, parsed.hour, 0);
      return slotDateTime.isBefore(now);
    } catch (_) {
      return false;
    }
  }

  String? firstAvailableSlot() {
    for (final t in timeSlots) {
      if (!isPastTime(t)) return t;
    }
    return null;
  }

  List<String> get availableSlots => timeSlots.where((t) => !isPastTime(t)).toList();
  List<String> get unavailableSlots => timeSlots.where((t) => isPastTime(t)).toList();

  void _ensureValidSelection() {
    if (selectedTime == null || isPastTime(selectedTime!)) {
      final nextSlot = firstAvailableSlot();
      if (nextSlot != null) {
        selectedTime = nextSlot;
        selectedSlots
          ..clear()
          ..add(nextSlot);
      } else {
        selectedSlots.clear();
        selectedTime = null;
      }
    }
  }

  /// Fetch join requests for a match
  Future<void> fetchJoinRequests(String matchId) async {
    try {
      isLoadingRequests.value = true;
      joinRequests.clear();
      
      final response = await repository.getRequestPlayersOpenMatch(matchId: matchId,type: "MatchCreator");
      
      if (response != null && response.requests != null) {
        joinRequests.value = response.requests!.map((request) => {
          'id': request.id ?? '',
          'name': request.requester?.name ?? '',
          'lastName': request.requester?.lastName ?? '',
          'profilePic': request.requester?.profilePic ?? '',
          // 'level': request.level ?? '',
        }).toList();
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "Error fetching join requests: $e", level: LogLevel.error);
    } finally {
      isLoadingRequests.value = false;
    }
  }

  /// Accept a join request
  Future<void> acceptRequest(String requestId, String matchId) async {
    try {
      acceptingRequestId.value = requestId;
      final body = {
        "requestId": requestId,
        "action": "accept",
        "type": "MatchCreator"
      };
      await repository.acceptOrRejectRequestPlayer(body: body);
      
      // Remove from requests list
      joinRequests.removeWhere((request) => request['id'] == requestId);

      // Refresh matches
      await fetchMatchesForSelection();
    } catch (e) {
      CustomLogger.logMessage(msg: "Error accepting request: $e", level: LogLevel.error);
    } finally {
      acceptingRequestId.value = '';
    }
  }

  /// Reject a join request
  Future<void> rejectRequest(String requestId, String matchId) async {
    try {
      rejectingRequestId.value = requestId;
      final body = {
        "requestId": requestId,
        "action": "reject"
      };
      
      await repository.acceptOrRejectRequestPlayer(body: body);
      
      // Remove from requests list
      joinRequests.removeWhere((request) => request['id'] == requestId);
    } catch (e) {
      CustomLogger.logMessage(msg: "Error rejecting request: $e", level: LogLevel.error);
    } finally {
      rejectingRequestId.value = '';
    }
  }

  /// Send Booking Invitation
  Future<void> sendBookingInvitation(String bookingId) async {
    try {
      isSendingInvitation.value = true;
      print("Sending booking invitation for: $bookingId");
      final response = await repository.sendBookingInvitation(bookingId: bookingId, sendNotifications: true);
      if (response.status == 200) {
        invitationSent.value = true;
        await fetchNearByPlayers(bookingId: bookingId);
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "Error sending invitation: $e", level: LogLevel.error);
    } finally {
      isSendingInvitation.value = false;
    }
  }

  /// Find Near By Players Api--------------------------------------------------
  Future<void> fetchNearByPlayers({String search = '', String? bookingId = ''}) async {
    try {
      isLoadingNearbyPlayers.value = true;
      currentPage.value = 1;
      currentBookingId.value = bookingId ?? '';
      nearbyPlayers.clear();
      
      final response = await repository.findNearByPlayer(
        search: search,
        bookingId: bookingId,
        page: currentPage.value,
        limit: 10,
      );
      
      if(response.status == 200 && response.players != null){
        totalPages.value = response.totalPages ?? 1;
        hasMore.value = currentPage.value < totalPages.value;
        
        nearbyPlayers.value = response.players!.map((player) => {
          'id': player.id ?? '',
          'name': player.name ?? '',
          // 'lastName': player.lastName ?? '',
          'profilePic': player.profilePic ?? '',
          'city': player.city ?? '',
          'cityName': player.cityName ?? '',
          'level': player.level ?? '',
          'xpPoints': player.xpPoints ?? '',
          'totalMatchesPlayed': player.totalMatchesPlayed ?? '',
          'hasPendingRequest': player.hasPendingRequest??false
        }).toList();
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "Error fetching nearby players: $e", level: LogLevel.error);
    } finally {
      isLoadingNearbyPlayers.value = false;
    }
  }

  Future<void> loadMoreNearbyPlayers() async {
    if (isLoadingMore.value || !hasMore.value || currentBookingId.value.isEmpty) return;
    
    try {
      isLoadingMore.value = true;
      currentPage.value++;
      
      final response = await repository.findNearByPlayer(
        bookingId: currentBookingId.value,
        page: currentPage.value,
        limit: 10,
      );
      
      if(response.status == 200 && response.players != null){
        totalPages.value = response.totalPages ?? 1;
        hasMore.value = currentPage.value < totalPages.value;
        
        final newPlayers = response.players!.map((player) => {
          'id': player.id ?? '',
          'name': player.name ?? '',
          'profilePic': player.profilePic ?? '',
          'city': player.city ?? '',
          'cityName': player.cityName ?? '',
          'level': player.level ?? '',
          'xpPoints': player.xpPoints ?? '',
          'totalMatchesPlayed': player.totalMatchesPlayed ?? '',
          'hasPendingRequest': player.hasPendingRequest??false
        }).toList();
        
        nearbyPlayers.addAll(newPlayers);
      }
    } catch (e) {
      currentPage.value--;
      CustomLogger.logMessage(msg: "Error loading more players: $e", level: LogLevel.error);
    } finally {
      isLoadingMore.value = false;
    }
  }

  ///Date Picker----------------------------------------------------------------
  Future<void> openDatePicker(BuildContext context) async {

    final DateTime today = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade800,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textTheme: TextTheme(
              // Header (month/year)
              headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              // Days of week (Mon, Tue, ...)
              titleSmall: TextStyle(fontSize: 14),
              // Date numbers
              bodyLarge: TextStyle(fontSize: 16),
              // Buttons (CANCEL/OK)
              labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),

          ),
          child: Transform.scale(
            scale: 0.9, // 👈 Adjust this to control overall calendar height
            child: child!,
          ),
        );
      },
    );
    if (picked != null) {
      selectedDate.value = picked;
      dateTimelineController.animateToDate(picked);

      // // Refresh slots for all selected courts for the new date
      // for (String courtId in selectedCourtIds) {
      //   await getAvailableCourtsById(
      //       registerClubId: registerClubId.value,
      //       courtId: courtId
      //   );
      // }
    }
  }
  final EasyDatePickerController dateTimelineController = EasyDatePickerController();

  @override
  void onClose() {
    nearbyPlayersScrollController.dispose();
    super.onClose();
  }
}