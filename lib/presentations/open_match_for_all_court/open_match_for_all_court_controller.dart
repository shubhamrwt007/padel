import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:padel_mobile/configs/components/snack_bars.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';
import 'package:padel_mobile/core/endpoitns.dart';
import 'package:padel_mobile/data/response_models/openmatch_model/open_match_booking_model.dart';
import 'package:padel_mobile/data/response_models/openmatch_model/open_match_model.dart';
import 'package:padel_mobile/handler/logger.dart';
import 'package:padel_mobile/repositories/openmatches/open_match_repository.dart';
import 'package:padel_mobile/repositories/score_board_repo/score_board_repository.dart';
import 'package:flutter/material.dart';
import 'package:padel_mobile/presentations/wallet/widgets/payment_for_wallet.dart';
import 'package:padel_mobile/services/payment_services/razorpay.dart';
import 'package:padel_mobile/presentations/profile/profile_controller.dart';

class OpenMatchForAllCourtController extends GetxController {
  final isMyBooking = false.obs;
  Rx<bool> viewUnavailableSlots = false.obs;
  RxList<String> selectedSlots = <String>[].obs;
  RxString selectedTimeFilter = 'morning'.obs;
  RxString selectedGameLevel = 'Game Level'.obs;
  RxBool isGameLevelSelected = false.obs;
  RxInt expandedIndex = (-1).obs;

  String? selectedTime;
  Rx<DateTime> selectedDate = DateTime.now().obs;
  RxBool isLoading = false.obs;
  Rx<OpenMatchModel?> createdMatch = Rx<OpenMatchModel?>(null);
  Rx<OpenMatchBookingModel?> matchesBySelection = Rx<OpenMatchBookingModel?>(null);
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

  // Scoreboard
  final ScoreBoardRepository scoreBoardRepository = Get.put(ScoreBoardRepository());
  final GetStorage storage = GetStorage();
  RxBool isCheckingScoreboard = false.obs;
  RxString loadingMatchId = ''.obs;
  
  // Category and Location IDs
  RxString categoryId = ''.obs;
  RxString locationId = ''.obs;

  // Payment
  RazorpayPaymentService? _paymentService;
  ProfileController profileController = Get.put(ProfileController());
  RxBool isAddingBalance = false.obs;
  
  // Store payment context
  OpenMatchBookingData? _pendingMatch;
  String? _pendingPrefferedTeam;
  String? _pendingOrderId;

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

  Rx<DateTime> focusedDate = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    
    // Set default tab based on current time
    final now = DateTime.now();
    final hour = now.hour;
    if (hour >= 6 && hour < 12) {
      selectedTimeFilter.value = 'morning';
    } else if (hour >= 12 && hour < 18) {
      selectedTimeFilter.value = 'afternoon';
    } else {
      selectedTimeFilter.value = 'evening';
    }
    
    // Initialize payment service
    _paymentService = RazorpayPaymentService();
    _paymentService!.onPaymentSuccess = (response) {
      _onPaymentSuccess(response.paymentId ?? '', response.orderId ?? '', response.signature ?? '');
    };
    _paymentService!.onPaymentFailure = (response) {
      _onPaymentError(response.message ?? 'Payment failed');
    };
    _paymentService!.onExternalWallet = (response) {
      CustomLogger.logMessage(msg: 'External wallet: ${response.walletName}', level: LogLevel.debug);
    };
    
    // Get categoryId and locationId from arguments
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      categoryId.value = args['categoryId']?.toString() ?? '';
      locationId.value = args['location']?.toString() ?? '';
    }
    
    focusedDate.value = selectedDate.value;
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
  }

  ///Date Picker----------------------------------------------------------------
  Future<void> openDatePicker(BuildContext context) async {

    final DateTime today = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
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

  /// Get time period (morning, noon, night) for a given time slot
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
            return 'morning'; // default fallback
          }
        }
      }

      final hour = parsed.hour;

      if (hour >= 6 && hour < 12) {
        return 'morning'; // 6 AM - 11:59 AM
      } else if (hour >= 12 && hour < 18) {
        return 'afternoon'; // 12 PM - 5:59 PM
      } else {
        return 'evening'; // 6 PM - 5:59 AM
      }
    } catch (_) {
      return 'morning';
    }
  }

  /// Filter slots by selected time period
  List<String> filterSlotsByPeriod(List<String> slots) {
    final filter = selectedTimeFilter.value;
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
        Get.snackbar("Error", "Please select a time slot");
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

      Get.snackbar("Success", "Match created successfully!");
    } catch (e) {
      Get.snackbar("Error", e.toString());
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
      final matchDate = formattedDate.isEmpty ? DateFormat("yyyy-MM-dd").format(DateTime.now()) : formattedDate;
      final userId = storage.read("userId")??"";
      final filter = isMyBooking.value ? 'myMatch' : 'allMatches';
      final response = await repository.getOpenMatchBookings(
        userid: userId,
        filter: filter,
        type: '',
        matchDate: matchDate,
        locationId: locationId.value.isNotEmpty ? locationId.value : null,
        categoryId: categoryId.value.isNotEmpty ? categoryId.value : null,
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
      Get.snackbar("Error", "Failed to fetch join requests");
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

      // SnackBarUtils.showSuccessSnackBar("Request accepted successfully");

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
      // SnackBarUtils.showSuccessSnackBar("Request rejected");
    } catch (e) {
      CustomLogger.logMessage(msg: "Error rejecting request: $e", level: LogLevel.error);
    } finally {
      rejectingRequestId.value = '';
    }
  }
  /// Find Near By Players Api--------------------------------------------------
  Future<void> fetchNearByPlayers({String search = '',required String bookingId}) async {
    try {
      isLoadingNearbyPlayers.value = true;
      nearbyPlayers.clear();

      final response = await repository.findNearByPlayer(search: search,bookingId: bookingId);
      if(response.status == 200 && response.players != null){
        nearbyPlayers.value = response.players!.map((player) => {
          'id': player.id ?? '',
          'name': player.name ?? '',
          // 'lastName': player.lastName ?? '',
          'profilePic': player.profilePic ?? '',
          'city': player.city ?? '',
          'cityName' : player.cityName ?? '',
          'level': player.level ?? '',
          'totalMatchesPlayed': player.totalMatchesPlayed ?? '',
          'xpPoints': player.xpPoints ?? '',
          "hasPendingRequest":player.hasPendingRequest??false
        }).toList();
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "Error fetching nearby players: $e", level: LogLevel.error);
    } finally {
      isLoadingNearbyPlayers.value = false;
    }
  }

  /// Count total players in match
  int getTotalPlayersCount(OpenMatchBookingData? matchData) {
    if (matchData == null) return 0;
    final teamACount = matchData.teamA?.length ?? 0;
    final teamBCount = matchData.teamB?.length ?? 0;
    return teamACount + teamBCount;
  }

  /// Create Scoreboard for Open Match--------------------------------------------------------
  Future<void> createScoreBoardForOpenMatch({required OpenMatchBookingData matchData}) async {
    try {
      final matchId = matchData.sId ?? '';
      if (matchId.isEmpty) {
        SnackBarUtils.showErrorSnackBar("Match ID not available");
        return;
      }

      // Check if logged-in user is part of the match (in teamA or teamB)
      final userId = storage.read('userId');
      if (userId == null) {
        SnackBarUtils.showErrorSnackBar("User not logged in");
        return;
      }

      bool isUserInMatch = false;
      
      // Check in teamA
      for (final player in matchData.teamA ?? []) {
        if (player.userId?.sId == userId) {
          isUserInMatch = true;
          break;
        }
      }

      // Check in teamB if not found in teamA
      if (!isUserInMatch) {
        for (final player in matchData.teamB ?? []) {
          if (player.userId?.sId == userId) {
            isUserInMatch = true;
            break;
          }
        }
      }

      // Only proceed if user is part of the match
      if (!isUserInMatch) {
        SnackBarUtils.showErrorSnackBar("You must be part of the match to create a scoreboard");
        return;
      }

      isCheckingScoreboard.value = true;
      loadingMatchId.value = matchId;

      // First, check if scoreboard already exists for this match
      final checkResponse = await scoreBoardRepository.getScoreBoard(bookingId: matchId);

      bool scoreboardExists = false;

      if (checkResponse.data != null) {
        if (checkResponse.data is List) {
          scoreboardExists = (checkResponse.data as List).isNotEmpty;
        } else {
          scoreboardExists = true;
        }
      }

      if (scoreboardExists) {
        isCheckingScoreboard.value = false;
        Get.toNamed(RoutesName.scoreBoard, arguments: {
          "bookingId": matchId,
          "openMatchId": matchId,
        });
        return;
      }

      // --- Create scoreboard ---
      final matchTimeStr = (matchData.matchTime?.isNotEmpty == true)
          ? matchData.matchTime!.first
          : (matchData.slot?.isNotEmpty == true &&
                  matchData.slot!.first.slotTimes?.isNotEmpty == true)
              ? matchData.slot!.first.slotTimes!.first.time ?? ""
              : "";

      final courtName = matchData.slot?.isNotEmpty == true
          ? matchData.slot!.first.courtName ?? ""
          : "";

      final clubName = matchData.clubId?.clubName ?? "";

      // Build teams from match data
      List<Map<String, dynamic>> teams = [];
      
      // Team A
      if (matchData.teamA?.isNotEmpty == true) {
        teams.add({
          "name": "Team A",
          "players": matchData.teamA!.map((player) => {
            "name": "${player.userId?.name ?? ''} ${player.userId?.lastName ?? ''}".trim(),
            "playerId": player.userId?.sId ?? "",
          }).toList(),
        });
      } else {
        teams.add({
          "name": "Team A",
          "players": [],
        });
      }

      // Team B
      if (matchData.teamB?.isNotEmpty == true) {
        teams.add({
          "name": "Team B",
          "players": matchData.teamB!.map((player) => {
            "name": "${player.userId?.name ?? ''} ${player.userId?.lastName ?? ''}".trim(),
            "playerId": player.userId?.sId ?? "",
          }).toList(),
        });
      } else {
        teams.add({
          "name": "Team B",
          "players": [],
        });
      }

      final body = {
        "bookingId": matchId,
        "matchDate": matchData.matchDate ?? "",
        "matchTime": matchTimeStr,
        "userId": storage.read("userId") ?? "",
        "courtName": courtName,
        "clubName": clubName,
        "openMatchId": matchId,
        "teams": teams,
      };

      final response = await scoreBoardRepository.createScoreBoard(data: body);

      isCheckingScoreboard.value = false;

      if (response.success == true) {
        Get.toNamed(RoutesName.scoreBoard, arguments: {
          "bookingId": matchId,
          "openMatchId": matchId,
        });
      }
    } catch (e) {
      isCheckingScoreboard.value = false;
      CustomLogger.logMessage(msg: "Error creating scoreboard: $e", level: LogLevel.error);
      SnackBarUtils.showErrorSnackBar("Failed to load or create scoreboard");
    } finally {
      loadingMatchId.value = '';
    }
  }

  /// Direct Join Admin Match---------------------------------------------------
  Future<void> directJoinAdminMatch({
    required OpenMatchBookingData? match,
    required String prefferedTeam,
    String? razorpayOrderId,
    String? razorpaySignature,
    String? razorpayPaymentId
  }) async {
    try {
      final matchId = match?.sId ?? '';

      final isPendingMatch = match?.openMatchStatus == "pending";
      final body = {
        "matchId": matchId,
        "prefferedTeam": prefferedTeam,
        if (razorpayOrderId != null) "razorpay_order_id": razorpayOrderId,
        if (razorpaySignature != null) "razorpay_signature": razorpaySignature,
        if (razorpayPaymentId != null) "razorpay_payment_id":razorpayPaymentId
      };

      CustomLogger.logMessage(msg: "directJoinAdminMatch body: $body", level: LogLevel.info);
      final response = await repository.directJoinAdminMatch(body: body, isPendingMatch: isPendingMatch);
      CustomLogger.logMessage(msg: "directJoinAdminMatch response: $response", level: LogLevel.info);

      if (razorpayOrderId == null) {
        // First call - store order ID and navigate to payment
        final orderId = response['orderId'];
        final amount = response['perShare'] ?? response['amount'] ?? 0.0;
        
        CustomLogger.logMessage(msg: "Order ID: $orderId, Amount: $amount", level: LogLevel.info);
        
        if (orderId != null) {
          // Store context for payment callback
          _pendingMatch = match;
          _pendingPrefferedTeam = prefferedTeam;
          _pendingOrderId = orderId;
          
          // Navigate to payment page with order ID
          final result = await Get.to(
            () => PaymentForWallet(),
            arguments: {
              'match': match,
              'prefferedTeam': prefferedTeam,
              'razorpay_order_id': orderId,
              'totalAmount': amount,
              'controller': this,
            },
          );
          
          CustomLogger.logMessage(msg: "Payment result: $result", level: LogLevel.info);
        } else {
          CustomLogger.logMessage(msg: "Failed to get order ID", level: LogLevel.info);

        }
      } else {
        // Second call - join completed
        CustomLogger.logMessage(msg: "Successfully joined the match!", level: LogLevel.info);

        await fetchMatchesForSelection();
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "Error in directJoinAdminMatch: $e", level: LogLevel.error);
    }
  }

  /// Initiate Admin Match Payment
  Future<void> initiateAdminMatchPayment(String orderId, double amount, String matchId, String prefferedTeam) async {
    try {
      isAddingBalance.value = true;
      await _paymentService!.initiatePayment(
        keyId: PaymentConfig.keyId,
        orderId: orderId,
        amount: amount.toDouble(),
        currency: 'INR',
        name: 'Swoot',
        description: 'Paying for court booking',
        image: 'https://rowthtech.s3.amazonaws.com/padel/Thu%20Jan%2022%202026%2013%3A38%3A20%20GMT%2B0530%20%28India%20Standard%20Time%29Padel_logo.svg',
        userEmail: profileController.profileModel.value?.response?.email??"",
        userContact: profileController.profileModel.value?.response?.phoneNumber.toString()??"",
      );
    } catch (e) {
      CustomLogger.logMessage(msg: "Payment initiation error: $e", level: LogLevel.error);
      isAddingBalance.value = false;
    }
  }

  void _onPaymentSuccess(String paymentId, String orderId, String signature) {
    CustomLogger.logMessage(msg: "Payment success - PaymentId: $paymentId, OrderId: $orderId, Signature: $signature", level: LogLevel.info);
    isAddingBalance.value = false;
    
    // Call directJoinAdminMatch with payment details
    if (_pendingMatch != null && _pendingPrefferedTeam != null && _pendingOrderId != null) {
      directJoinAdminMatch(
        match: _pendingMatch,
        prefferedTeam: _pendingPrefferedTeam!,
        razorpayOrderId: _pendingOrderId,
        razorpaySignature: signature,
        razorpayPaymentId: paymentId
      );
    }
    
    Get.back(result: true);
  }

  void _onPaymentError(String error) {
    CustomLogger.logMessage(msg: "Payment failed: $error", level: LogLevel.error);
    isAddingBalance.value = false;
  }

  @override
  void onClose() {
    _paymentService?.dispose();
    super.onClose();
  }
}